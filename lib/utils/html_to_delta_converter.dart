import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class HtmlToDeltaConverter {
  static bool isHtmlContent(String text) {
    return text.contains(RegExp(r'<[^>]*>'));
  }
  
  static quill.Document htmlToDelta(String htmlString) {
    // Добавляем проверку на пустой HTML
    if (htmlString.trim().isEmpty) {
      return quill.Document();
    }
    
    // Проверяем, содержит ли HTML заголовки, и в этом случае используем ручную обработку
    final hasHeader = RegExp(r'<h[1-6]').hasMatch(htmlString);
    
    // Если есть заголовки, используем ручную обработку
    if (hasHeader) {
      return _fallbackHtmlToDelta(htmlString);
    }
    
    // Вначале пробуем использовать готовую библиотеку
    try {
      final delta = HtmlToDelta().convert(htmlString, transformTableAsEmbed: false);
      final document = quill.Document.fromDelta(delta);
      
      return document;
    } catch (e) {
      // Если библиотека не справилась, возвращаемся к ручной обработке
      return _fallbackHtmlToDelta(htmlString);
    }
  }
  
  // Резервный метод для преобразования HTML в Delta в случае, если основной не сработает
  static quill.Document _fallbackHtmlToDelta(String htmlString) {
    final document = quill.Document();
    
    final dom.Document htmlDoc = html_parser.parse(htmlString);
    
    // Обрабатываем body, если он существует, иначе обрабатываем весь документ
    final dom.Element? body = htmlDoc.querySelector('body');
    final List<dom.Node> nodes = body?.nodes ?? htmlDoc.nodes;
    
    // Храним текущую позицию в документе
    int position = 0;
    
    // Обрабатываем узлы и вставляем текст с форматированием
    for (final node in nodes) {
      final result = _processNode(node);
      final text = result.text;
      final attribute = result.attribute;
      
      if (text.isNotEmpty) {
        // Вставляем текст в документ
        document.insert(position, text);
        
        // Применяем атрибут, если он есть
        if (attribute != null) {
          document.format(position, text.length, attribute);
        }
        
        // Обновляем позицию
        position += text.length;
      }
    }
    
    return document;
  }
  
  // Вспомогательный класс для возврата текста и атрибута из обработчика узла
  static _NodeResult _processNode(dom.Node node) {
    if (node is dom.Element) {
      return _processElement(node);
    } else if (node is dom.Text) {
      // Возвращаем текст без форматирования
      return _NodeResult(node.text ?? '', null);
    }
    
    // Для неизвестных типов возвращаем пустой результат
    return _NodeResult('', null);
  }
  
  static _NodeResult _processElement(dom.Element element) {
    final String tagName = element.localName?.toLowerCase() ?? '';
    final String text = element.text ?? '';
    
    switch (tagName) {
      case 'p':
        // Обрабатываем параграф
        return _NodeResult(text, null);
      case 'strong':
      case 'b':
        // Обрабатываем жирный текст
        return _NodeResult(text, quill.Attribute.bold);
      case 'em':
      case 'i':
        // Обрабатываем курсив
        return _NodeResult(text, quill.Attribute.italic);
      case 'u':
        // Обрабатываем подчеркнутый текст
        return _NodeResult(text, quill.Attribute.underline);
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        // Для заголовков используем h1 атрибут
        return _NodeResult(text, quill.Attribute.h1);
      case 'ul':
        // Обрабатываем маркированный список
        return _processListElement(element, 'ul');
      case 'ol':
        // Обрабатываем нумерованный список
        return _processListElement(element, 'ol');
      case 'li':
        // Обрабатываем элементы списка
        return _NodeResult(text, quill.Attribute.ul);
      case 'br':
        // Обрабатываем разрыв строки
        return _NodeResult('\n', null);
      case 'span':
        // Обрабатываем span как обычный текст (без цвета)
        return _NodeResult(text, null);
      case 'font':
        // Обрабатываем font тег как обычный текст (без цвета)
        return _NodeResult(text, null);
      case 'div':
        // Обрабатываем div как обычный контейнер, просто возвращаем текст
        return _NodeResult(text, null);
      default:
        // Для всех остальных элементов просто возвращаем текст
        return _NodeResult(text, null);
    }
  }
  
  static _NodeResult _processListElement(dom.Element element, String listType) {
    String allText = '';
    quill.Attribute? attribute;
    
    for (final child in element.nodes) {
      if (child is dom.Element && child.localName == 'li') {
        final text = child.text ?? '';
        allText += text;
        
        // Применяем атрибут списка к последнему тексту
        attribute = listType == 'ul' ? quill.Attribute.ul : quill.Attribute.ol;
      } else if (child is dom.Text) {
        final text = child.text ?? '';
        allText += text;
      }
    }
    
    return _NodeResult(allText, attribute);
  }
  

}

// Вспомогательный класс для возврата результата обработки узла
class _NodeResult {
  final String text;
  final quill.Attribute? attribute;
  
  _NodeResult(this.text, this.attribute);
}
# Настройка автоматического обновления названия приложения для iOS

Для того чтобы приложение iOS отображало правильное название из переменной APP_NAME в файле .env, необходимо настроить Xcode следующим образом:

## Настройка Build Phase в Xcode

1. Откройте проект в Xcode: `open ios/Runner.xcworkspace`

2. В Xcode:
   - Выберите проект в Navigator
   - Выберите таргет "Runner"
   - Перейдите на вкладку "Build Phases"
   - Нажмите "+" и выберите "New Run Script Phase"

3. Добавьте следующий скрипт:
   ```bash
   #!/bin/sh
   # Проверяем, что мы в нужной директории
   cd "$SRCROOT"
   
   # Используем ruby для обновления Info.plist (так как PlistBuddy может не быть доступен в PowerShell на всех системах)
   ruby -e "
   require 'plist'
   env_file = '../.env'
   if File.exist?(env_file)
     File.readlines(env_file).each do |line|
       if line.start_with?('APP_NAME=')
         app_name = line.split('=', 2)[1].strip
         # Убираем кавычки если они есть
         if (app_name.start_with?('\"') && app_name.end_with?('\"')) ||
            (app_name.start_with?("'") && app_name.end_with?("'")) 
           app_name = app_name[1..-2]
         end
         if app_name
           plist = Plist.parse_xml('Runner/Info.plist')
           plist['CFBundleDisplayName'] = app_name
           plist['CFBundleName'] = app_name
           File.open('Runner/Info.plist', 'w') { |f| f.write(plist.to_plist) }
           puts 'Updated CFBundleDisplayName and CFBundleName to: ' + app_name
         end
         break
       end
     end
   end
   "
   ```

4. Убедитесь, что этот Run Script Phase находится перед "Compile Sources" phase

## Альтернативный способ (для разработчиков на Windows)

Если вы используете Windows, вы можете использовать PowerShell скрипт, который был создан в проекте:

1. В Xcode добавьте Run Script Phase с содержимым:
   ```bash
   #!/bin/sh
   cd "$SRCROOT"
   if [ -f "update_app_name.ps1" ]; then
       powershell.exe -ExecutionPolicy Bypass -File "./update_app_name.ps1"
   fi
   ```

## Важно

- Убедитесь, что в вашем .env файле APP_NAME установлен правильно:
  ```
  APP_NAME="Турбо чайна-бабка"
  ```

- После настройки скрипта, при каждой сборке iOS приложения будет автоматически обновляться название приложения в соответствии с APP_NAME из .env файла.

- Не забудьте установить gem 'plist' в вашей системе, если вы используете Ruby скрипт:
  ```
  gem install plist
  ```
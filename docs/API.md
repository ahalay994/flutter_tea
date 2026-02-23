# API Documentation

## Overview

API endpoints for the Tea Catalog application. All endpoints use a unified response format:

**Success Response:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "error": "Error details"
}
```

---

## Authentication

All routes are protected by global middleware `auth.global.ts`. A valid `auth` cookie is required.

---

## Endpoints

### POST `/api/login`

Authentication endpoint to set the auth cookie.

**Request Body:**
```json
{
  "login": "string",
  "password": "string"
}
```

**Response (Success):**
```json
{
  "success": true
}
```

**Response (Error):**
- Status: 401
- Message: "Invalid credentials"

---

### GET `/api/tea`

Get all teas with optional filtering (no pagination).

**Query Parameters:**
- `search` (string) - Search in name, description, brewingGuide, temperature, weight
- `countries` (string) - Comma-separated country IDs
- `types` (string) - Comma-separated type IDs
- `flavors` (string) - Comma-separated flavor IDs
- `appearances` (string) - Comma-separated appearance IDs

**Response:**
```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": number,
        "name": string,
        "countryId": number,
        "typeId": number,
        "appearanceId": number | null,
        "description": string,
        "brewingGuide": string,
        "temperature": string,
        "weight": string,
        "Flavors": [number],
        "Images": [
          {
            "id": number,
            "name": string,
            "url": string,
            "status": string
          }
        ],
        "createdAt": string,
        "updatedAt": string
      }
    ],
    "totalCount": number
  }
}
```

---

### GET `/api/device-tea/pagination`

Get teas with pagination and filtering.

**Query Parameters:**
- `search` (string) - Search in name, description, brewingGuide, temperature, weight
- `countries` (string) - Comma-separated country IDs
- `types` (string) - Comma-separated type IDs
- `flavors` (string) - Comma-separated flavor IDs
- `appearances` (string) - Comma-separated appearance IDs
- `page` (string) - Page number (default: 1)
- `perPage` (string) - Items per page (default: 10)

**Response:**
```json
{
  "success": true,
  "data": {
    "data": [...],
    "pagination": {
      "currentPage": number,
      "totalPages": number,
      "perPage": number,
      "hasMore": boolean,
      "totalCount": number
    }
  }
}
```

---

### GET `/api/device-tea/facets`
Получение фасетов (количество чаёв по каждому фильтру) с поддержкой мульти-тенантности. Требует передачи deviceId в query параметрах.

**Query Parameters:**
- `search` (string) - Search filter
- `countries` (string) - Comma-separated country IDs
- `types` (string) - Comma-separated type IDs
- `flavors` (string) - Comma-separated flavor IDs
- `appearances` (string) - Comma-separated appearance IDs

**Response:**
```json
{
  "success": true,
  "data": {
    "countries": [
      {
        "id": number,
        "name": string,
        "count": number
      }
    ],
    "types": [
      {
        "id": number,
        "name": string,
        "count": number
      }
    ],
    "appearances": [
      {
        "id": number,
        "name": string,
        "count": number
      }
    ],
    "flavors": [
      {
        "id": number,
        "name": string,
        "count": number
      }
    ]
  }
}
```

---

### GET `/api/tea/:id`

Get a single tea by ID.

**URL Parameter:**
- `id` (number) - Tea ID

**Response:**
```json
{
  "success": true,
  "data": {
    "id": number,
    "name": string,
    "countryId": number,
    "typeId": number,
    "appearanceId": number | null,
    "description": string,
    "brewingGuide": string,
    "temperature": string,
    "weight": string,
    "Flavors": [number],
    "Images": [...],
    "createdAt": string,
    "updatedAt": string
  }
}
```

---

### POST `/api/device-tea`
Создание нового чая с поддержкой мульти-тенантности. Требует передачи deviceId в теле запроса.

**Request Body:**
```json
{
  "name": string,
  "countryId": number | string,
  "typeId": number | string,
  "appearanceId": number | string | null,
  "description": string,
  "brewingGuide": string,
  "temperature": string,
  "weight": string,
  "Flavors": (number | string)[],
  "Images": [
    {
      "id": number,
      "name": string,
      "url": string,
      "status": "pending"
    }
  ]
}
```

**Notes:**
- If `countryId`, `typeId`, or `appearanceId` is a string, it will be created automatically
- `Flavors` can be IDs (number) or new flavor names (string)
- Only images with `status: "pending"` will be created

**Response:**
```json
{
  "success": true
}
```

---

### PUT `/api/tea/:id`

Update an existing tea.

**URL Parameter:**
- `id` (number) - Tea ID

**Request Body:**
```json
{
  "name": string,
  "countryId": number | string,
  "typeId": number | string,
  "appearanceId": number | string | null,
  "description": string,
  "brewingGuide": string,
  "temperature": string,
  "weight": string,
  "Flavors": (number | string)[],
  "Images": [
    {
      "id": number,
      "name": string,
      "url": string,
      "status": "pending" | "finished"
    }
  ]
}
```

**Notes:**
- Images without `id` and with `status: "pending"` will be created
- Images with `id` will be kept connected
- Images not in the list will be disconnected/deleted
- Flavors not in the list will be disconnected

**Response:**
```json
{
  "success": true,
  "data": {
    "id": number,
    "name": string,
    ...,
    "_meta": {
      "deletedImagesCount": number,
      "deletedImageIds": [number]
    }
  }
}
```

---

### DELETE `/api/tea/:id`

Delete a tea by ID.

**URL Parameter:**
- `id` (number) - Tea ID

**Response:**
```json
{
  "success": true
}
```

---

### GET `/api/country`

Get all countries.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": number,
      "name": string,
      "createdAt": string,
      "updatedAt": string
    }
  ]
}
```

---

### GET `/api/type`

Get all tea types.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": number,
      "name": string,
      "createdAt": string,
      "updatedAt": string
    }
  ]
}
```

---

### GET `/api/appearance`

Get all tea appearances.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": number,
      "name": string,
      "createdAt": string,
      "updatedAt": string
    }
  ]
}
```

---

### GET `/api/flavor`

Get all flavors.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": number,
      "name": string,
      "createdAt": string,
      "updatedAt": string
    }
  ]
}
```

---

### POST `/api/upload-image`

Upload an image to Cloudinary.

**Request Body (FormData):**
- `file` (File) - Image file

**Image Processing:**
- Converted to WebP format
- Quality: 75%
- Uploaded to Cloudinary folder: 'tea'

**Response:**
```json
{
  "success": true,
  "data": {
    "id": string,
    "name": string,
    "status": "pending",
    "url": string
  }
}
```

---

## Enums

### ImageStatus

- `pending` - Image uploaded but not yet saved to database
- `finished` - Image saved to database
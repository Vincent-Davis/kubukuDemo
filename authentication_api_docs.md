# API Documentation — Authentication Module

## Overview
Module authentication menyediakan sistem autentikasi berbasis token untuk user management. Menggunakan Django REST Framework Token Authentication dengan custom User model yang extends AbstractUser.

**Base Path**: `/api/auth/`

**Authentication Type**: Token-based (DRF Token)

## User Model Schema
```python
{
  "id": int,
  "username": str (unique),
  "email": str (unique, used for login),
  "role": "admin" | "user" (default: "user"),
  "isPremiumUser": bool (default: false),
  "first_name": str (optional),
  "last_name": str (optional),
  "created_at": datetime,
  "updated_at": datetime
}
```

**Notes**:
- `email` digunakan sebagai USERNAME_FIELD untuk login
- Password di-hash menggunakan Django's password hashing
- Token generated automatically saat register/login

---

## Endpoints

### **1. User Registration**
**Endpoint**: `POST /api/auth/register/`

**Authentication**: None (AllowAny)

**Purpose**: Register user baru dan return authentication token

**Request Body** (JSON):
```json
{
  "email": "user@example.com",
  "username": "johndoe",
  "password": "SecurePass123!",
  "password_confirm": "SecurePass123!",
  "role": "user",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Required Fields**:
- `email` (unique, valid email format)
- `username` (unique)
- `password` (min 8 chars, must pass Django password validation)
- `password_confirm` (must match password)

**Optional Fields**:
- `role` (default: "user", choices: "admin" | "user")
- `first_name`
- `last_name`

**Success Response**: 201 Created
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "user@example.com",
    "role": "user",
    "created_at": "2025-12-12T10:00:00Z",
    "updated_at": "2025-12-12T10:00:00Z"
  },
  "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
}
```

**Error Responses**: 

400 Bad Request - Validation errors
```json
{
  "error": "Registration failed",
  "details": {
    "email": ["User with this email already exists."],
    "password": ["This password is too common."],
    "password_confirm": ["Passwords do not match."],
    "username": ["User with this username already exists."]
  }
}
```

500 Internal Server Error
```json
{
  "error": "Registration failed",
  "details": {
    "server_error": ["Error message"]
  }
}
```

**Password Validation Rules**:
- Minimal 8 karakter
- Tidak boleh terlalu mirip dengan info user lain
- Tidak boleh password umum (Django common passwords list)
- Tidak boleh sepenuhnya numeric

---

### **2. User Login**
**Endpoint**: `POST /api/auth/login/`

**Authentication**: None (AllowAny)

**Purpose**: Authenticate user dan return token

**Request Body** (JSON):
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Success Response**: 200 OK
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "user@example.com",
    "role": "user",
    "created_at": "2025-12-12T10:00:00Z",
    "updated_at": "2025-12-12T10:00:00Z"
  },
  "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
}
```

**Error Responses**:

400 Bad Request - Missing fields
```json
{
  "error": "Login failed",
  "details": {
    "email": ["This field is required."],
    "password": ["This field is required."]
  }
}
```

401 Unauthorized - Invalid credentials
```json
{
  "error": "Login failed",
  "details": {
    "credentials": ["Invalid email or password."]
  }
}
```

401 Unauthorized - Account disabled
```json
{
  "error": "Login failed",
  "details": {
    "account": ["User account is disabled."]
  }
}
```

**Notes**:
- Token akan di-reuse jika sudah ada, atau dibuat baru jika belum
- Token tidak expire secara default (gunakan session timeout di production)

---

### **3. User Logout**
**Endpoint**: `POST /api/auth/logout/`

**Authentication**: Required (Token)

**Purpose**: Logout user dengan menghapus authentication token

**Headers**:
```
Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
```

**Request Body**: None

**Success Response**: 200 OK
```json
{
  "message": "Logout successful"
}
```

**Error Responses**:

400 Bad Request - Invalid token
```json
{
  "error": "Logout failed",
  "details": {
    "token": ["Invalid token"]
  }
}
```

401 Unauthorized - No token provided
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

### **4. Get User Profile**
**Endpoint**: `GET /api/auth/profile/`

**Authentication**: Required (Token)

**Purpose**: Retrieve current authenticated user's profile

**Headers**:
```
Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
```

**Success Response**: 200 OK
```json
{
  "user": {
    "id": 1,
    "username": "johndoe",
    "email": "user@example.com",
    "role": "user",
    "created_at": "2025-12-12T10:00:00Z",
    "updated_at": "2025-12-12T10:00:00Z"
  }
}
```

**Error Response**:

401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

### **5. Update User Profile**
**Endpoint**: `PUT /api/auth/profile/update/`

**Authentication**: Required (Token)

**Purpose**: Update current user's profile information

**Headers**:
```
Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
```

**Request Body** (JSON - all fields optional):
```json
{
  "username": "newusername",
  "email": "newemail@example.com",
  "first_name": "Jane",
  "last_name": "Smith"
}
```

**Updateable Fields**:
- `username` (must be unique)
- `email` (must be unique)
- `first_name`
- `last_name`

**Non-updateable Fields**:
- `password` (use separate password change endpoint if implemented)
- `role` (requires admin privileges)
- `isPremiumUser` (managed by system)

**Success Response**: 200 OK
```json
{
  "message": "Profile updated successfully",
  "user": {
    "id": 1,
    "username": "newusername",
    "email": "newemail@example.com",
    "role": "user",
    "created_at": "2025-12-12T10:00:00Z",
    "updated_at": "2025-12-12T10:05:00Z"
  }
}
```

**Error Responses**:

400 Bad Request - Duplicate data
```json
{
  "error": "Profile update failed",
  "details": {
    "username": ["Username already exists."],
    "email": ["Email already exists."]
  }
}
```

401 Unauthorized
```json
{
  "detail": "Authentication credentials were not provided."
}
```

---

## Authentication Flow

### Registration & Login Flow
```
1. Client → POST /api/auth/register/
2. Server → Create user, generate token
3. Server → Return user data + token
4. Client → Store token (localStorage, secure storage)
5. Client → Use token for authenticated requests
```

### Authenticated Request Flow
```
1. Client → Add header: Authorization: Token <token>
2. Server → Validate token
3. Server → Process request with user context
4. Server → Return response
```

### Logout Flow
```
1. Client → POST /api/auth/logout/ (with token)
2. Server → Delete token from database
3. Client → Remove token from storage
```

---

## Usage Examples

### **Register New User**
```bash
curl -X POST http://localhost:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "johndoe",
    "password": "SecurePass123!",
    "password_confirm": "SecurePass123!",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### **Login**
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'
```

### **Get Profile** (Authenticated)
```bash
curl -X GET http://localhost:8000/api/auth/profile/ \
  -H "Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
```

### **Update Profile** (Authenticated)
```bash
curl -X PUT http://localhost:8000/api/auth/profile/update/ \
  -H "Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Jane",
    "last_name": "Smith"
  }'
```

### **Logout** (Authenticated)
```bash
curl -X POST http://localhost:8000/api/auth/logout/ \
  -H "Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
```

---

## Security Considerations

### Password Security
- Passwords hashed menggunakan Django's PBKDF2 algorithm
- Password validation enforced (min length, complexity)
- Password never returned di response

### Token Management
- Token generated secara random dan unique
- Token stored di database dengan hash
- Logout menghapus token dari database

### Email as Username
- Email digunakan untuk login (lebih user-friendly)
- Username tetap unique dan required untuk display purposes

### Production Recommendations
- Implement token expiration
- Add rate limiting untuk login attempts
- Use HTTPS untuk semua requests
- Implement refresh token mechanism
- Add password reset functionality
- Add email verification

---

## Error Handling

**Standard Error Format**:
```json
{
  "error": "Error type",
  "details": {
    "field_name": ["Error message 1", "Error message 2"]
  }
}
```

**Common HTTP Status Codes**:
- `200 OK` - Request successful
- `201 Created` - User created successfully
- `400 Bad Request` - Validation errors
- `401 Unauthorized` - Authentication required or failed
- `500 Internal Server Error` - Server error

---

## Integration with Other Modules

### Using Authentication in Views
```python
from rest_framework.decorators import permission_classes
from rest_framework.permissions import IsAuthenticated

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_view(request):
    user = request.user  # Current authenticated user
    user_id = str(request.user.id)  # For filtering data
    is_premium = request.user.isPremiumUser  # Check premium status
    # ... rest of logic
```

### Accessing User Data
- `request.user` - Current User instance
- `request.user.id` - User ID
- `request.user.email` - User email
- `request.user.role` - User role (admin/user)
- `request.user.isPremiumUser` - Premium status

---

## Frontend Integration Example

### JavaScript/TypeScript Example
```javascript
// Register
const register = async (userData) => {
  const response = await fetch('http://localhost:8000/api/auth/register/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(userData)
  });
  const data = await response.json();
  if (response.ok) {
    localStorage.setItem('auth_token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
  }
  return data;
};

// Login
const login = async (email, password) => {
  const response = await fetch('http://localhost:8000/api/auth/login/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  const data = await response.json();
  if (response.ok) {
    localStorage.setItem('auth_token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
  }
  return data;
};

// Authenticated Request
const getProfile = async () => {
  const token = localStorage.getItem('auth_token');
  const response = await fetch('http://localhost:8000/api/auth/profile/', {
    headers: { 'Authorization': `Token ${token}` }
  });
  return await response.json();
};

// Logout
const logout = async () => {
  const token = localStorage.getItem('auth_token');
  await fetch('http://localhost:8000/api/auth/logout/', {
    method: 'POST',
    headers: { 'Authorization': `Token ${token}` }
  });
  localStorage.removeItem('auth_token');
  localStorage.removeItem('user');
};
```

---

File created: `authentication_api_docs.md`

# Splitzy Backend API

Node.js/Express backend for the Splitzy bill splitting application.

## Features

- User authentication (JWT-based)
- User profiles with dietary preferences
- Friends management
- Bill upload and management
- MongoDB database

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file:
```bash
cp .env.example .env
```

3. Update `.env` with your configuration:
- Set `MONGODB_URI` to your MongoDB connection string
- Set `JWT_SECRET` to a secure random string
- Adjust `PORT` if needed

4. Start MongoDB (if running locally):
```bash
mongod
```

5. Start the server:
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (protected)

### Users
- `GET /api/users/profile` - Get user profile (protected)
- `PUT /api/users/profile` - Update user profile (protected)
- `PUT /api/users/preferences` - Update dietary preferences (protected)

### Friends
- `GET /api/friends` - Get friends list (protected)
- `GET /api/friends/search?email=` - Search users by email (protected)
- `POST /api/friends` - Add friend by email (protected)
- `DELETE /api/friends/:friendId` - Remove friend (protected)

### Bills
- `POST /api/bills` - Upload new bill with image (protected)
- `GET /api/bills` - Get all bills for user (protected)
- `GET /api/bills/:id` - Get single bill (protected)
- `PUT /api/bills/:id/items` - Update bill items manually (protected)
- `DELETE /api/bills/:id` - Delete bill (protected)

## API Response Format

Success:
```json
{
  "success": true,
  "data": { ... }
}
```

Error:
```json
{
  "success": false,
  "message": "Error message"
}
```

## Authentication

Protected routes require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Database Models

### User
- email, password, name
- preferences: drinks_alcohol, eats_meat, meat_types[]
- friends: [User IDs]

### Bill
- uploadedBy, imageUrl
- participants: [User IDs]
- items: [{ name, quantity, cost }]
- totalAmount, status
- restaurant: { name, type }

## Environment Variables

- `PORT` - Server port (default: 3000)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT signing
- `JWT_EXPIRE` - JWT expiration time (default: 7d)
- `NODE_ENV` - Environment (development/production)
- `UPLOAD_DIR` - Directory for uploaded files (default: ./uploads)

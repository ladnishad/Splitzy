# Splitzy - AI-Powered Bill Splitting App

An intelligent bill splitting application focused on restaurant and bar bills, with user preferences and AI-powered receipt parsing.

## 🎯 Project Overview

Splitzy allows users to:
- Upload pictures of restaurant/bar bills
- Add friends and manage friend lists
- Set dietary preferences (alcohol consumption, meat preferences)
- Split bills intelligently based on user preferences (Phase 2)
- AI-powered receipt parsing using OpenAI Vision API (Phase 2)

## 📁 Project Structure

```
Splitzy/
├── backend/              # Node.js/Express API
│   ├── src/
│   │   ├── models/       # MongoDB models (User, Bill)
│   │   ├── routes/       # API routes
│   │   ├── controllers/  # Business logic
│   │   ├── middleware/   # Auth middleware
│   │   └── config/       # Database & JWT config
│   └── uploads/          # Uploaded bill images
│
├── ios-app/              # SwiftUI iOS application
│   ├── Models/           # Data models
│   ├── Services/         # API service & ViewModels
│   └── Views/            # SwiftUI views
│       ├── Auth/         # Login & Signup
│       ├── Home/         # Bills list
│       ├── Bills/        # Bill details & upload
│       ├── Friends/      # Friends management
│       └── Profile/      # User profile
│
└── docs/                 # Documentation
```

## 🚀 Phase 1 - MVP Foundation (Current)

### ✅ Completed Features

**Backend API:**
- User authentication (JWT-based)
- User profiles with dietary preferences
- Friends management (add/remove/search)
- Bill upload with image storage
- RESTful API endpoints

**iOS App:**
- SwiftUI interface following Apple HIG
- Authentication flow (login/signup)
- Profile management with preferences
- Friends list and search
- Bill upload with image picker
- Bills list view
- Tab-based navigation

### Tech Stack

**Backend:**
- Node.js + Express
- MongoDB + Mongoose
- JWT authentication
- Multer (file uploads)
- bcryptjs (password hashing)

**iOS:**
- SwiftUI (iOS 16+)
- PhotosPicker
- Async/await networking
- MVVM architecture

## 🔧 Setup & Installation

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file:
```bash
cp .env.example .env
```

4. Update `.env` with your MongoDB URI and JWT secret:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/splitzy
JWT_SECRET=your_secure_secret_here
JWT_EXPIRE=7d
NODE_ENV=development
UPLOAD_DIR=./uploads
```

5. Start MongoDB (if local):
```bash
mongod
```

6. Run the server:
```bash
# Development mode
npm run dev

# Production mode
npm start
```

The API will be available at `http://localhost:3000`

### iOS App Setup

1. Open Xcode

2. Create a new iOS App project:
   - Name: Splitzy
   - Interface: SwiftUI
   - Language: Swift
   - Minimum iOS: 16.0

3. Copy all Swift files from `ios-app/` directory into your Xcode project

4. Update API base URL in `APIService.swift`:
   - For Simulator: `http://localhost:3000/api`
   - For Device: `http://YOUR_COMPUTER_IP:3000/api`

5. Build and run the project

## 📱 App Features

### Authentication
- **Sign Up**: Create account with email and password
- **Login**: JWT-based authentication
- **Persistent sessions**: Auto-login on app restart

### Profile
- View and edit user information
- Set dietary preferences:
  - Drinks alcohol (yes/no)
  - Eats meat (yes/no)
  - Specific meat types (beef, chicken, pork, lamb, fish, seafood)

### Friends
- Search users by email
- Add/remove friends
- View friend preferences
- Swipe to delete friends

### Bills
- Upload bill images from photo library
- Add restaurant name and type (restaurant/bar)
- Select participants from friends list
- View all bills
- Bill details with participants and items

## 🔐 API Endpoints

### Authentication
```
POST   /api/auth/signup     - Register new user
POST   /api/auth/login      - Login user
GET    /api/auth/me         - Get current user
```

### Users
```
GET    /api/users/profile      - Get user profile
PUT    /api/users/profile      - Update user profile
PUT    /api/users/preferences  - Update dietary preferences
```

### Friends
```
GET    /api/friends              - Get friends list
GET    /api/friends/search       - Search users by email
POST   /api/friends              - Add friend
DELETE /api/friends/:friendId   - Remove friend
```

### Bills
```
POST   /api/bills           - Upload new bill
GET    /api/bills           - Get all bills
GET    /api/bills/:id       - Get single bill
PUT    /api/bills/:id/items - Update bill items
DELETE /api/bills/:id       - Delete bill
```

## 🎨 Design Guidelines

The iOS app strictly follows [Apple's Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/components):

- Native SwiftUI components
- SF Symbols for icons
- Standard navigation patterns
- System fonts and colors
- Apple-like interactions

## 🔮 Phase 2 - AI Integration (Next Steps)

### Planned Features:
1. **OpenAI Vision API Integration**
   - Automatic receipt parsing
   - Item extraction with quantities and prices
   - OCR for restaurant names

2. **Smart Bill Splitting**
   - AI-powered item assignment based on preferences
   - Automatic alcohol item filtering
   - Meat dish detection and assignment
   - Fair split calculation

3. **Enhanced Features**
   - Split history
   - Payment tracking
   - Notifications
   - Bill splitting suggestions

## 🧪 Testing

### Backend Testing
```bash
cd backend
npm test
```

### Manual API Testing
Use tools like Postman or curl to test endpoints. Example:

```bash
# Signup
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🐛 Troubleshooting

### Backend Issues
- **MongoDB connection failed**: Ensure MongoDB is running
- **Port already in use**: Change PORT in `.env`
- **JWT errors**: Verify JWT_SECRET is set in `.env`

### iOS Issues
- **Network requests fail**: Check baseURL in APIService.swift
- **Build errors**: Ensure iOS 16.0+ deployment target
- **Images not loading**: Verify backend URL is accessible from device/simulator

## 📝 License

This project is for educational purposes.

## 🤝 Contributing

This is an MVP project. Future enhancements will include AI integration and advanced splitting algorithms.

---

**Current Status**: Phase 1 Complete ✅
**Next Phase**: AI Integration with OpenAI Vision API

# Splitzy - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Backend Setup

1. **Install dependencies**
```bash
cd backend
npm install
```

2. **Configure environment**
```bash
cp .env.example .env
# Edit .env and set your MongoDB URI and JWT_SECRET
```

3. **Start the server**
```bash
npm run dev
```

Server runs on `http://localhost:3000`

### iOS App Setup

1. **Open the Xcode project**:
```bash
open ios-app-xcode/Splitzy/Splitzy.xcodeproj
```

2. **Update API URL** (if needed) in `Services/APIService.swift`:
```swift
private let baseURL = "http://localhost:3000/api"  // Already set for simulator
```

3. **Select a simulator** (e.g., iPhone 15 Pro) from the top bar

4. **Press Cmd + R** to build and run

## 📱 Testing the App

### Create Test Users

1. Launch the app
2. Tap "Sign Up"
3. Create an account with:
   - Name: Your name
   - Email: test@example.com
   - Password: password123

### Add Friends

1. Go to Friends tab
2. Tap "+" button
3. Search for friend's email
4. Tap add button

### Upload a Bill

1. Go to Bills tab
2. Tap "+" button
3. Select a photo of a receipt
4. Enter restaurant name
5. Select restaurant type (Restaurant/Bar)
6. Select friends to split with
7. Tap "Upload"

### Set Preferences

1. Go to Profile tab
2. Toggle dietary preferences:
   - Drinks Alcohol
   - Eats Meat
   - Select specific meat types
3. Tap "Save Preferences"

## 🔑 Key Features

### ✅ Implemented in Phase 1

- User authentication (signup/login)
- User profiles with dietary preferences
- Friends management
- Bill upload with images
- Bills list and details
- Apple HIG compliant UI

### 🔮 Coming in Phase 2

- OpenAI Vision API integration
- Automatic receipt parsing
- Smart bill splitting based on preferences
- Item-level assignment
- Payment tracking

## 🛠️ API Endpoints

Base URL: `http://localhost:3000/api`

**Authentication:**
- `POST /auth/signup` - Create account
- `POST /auth/login` - Login
- `GET /auth/me` - Get current user

**Friends:**
- `GET /friends` - List friends
- `POST /friends` - Add friend
- `DELETE /friends/:id` - Remove friend
- `GET /friends/search?email=` - Search users

**Bills:**
- `POST /bills` - Upload bill
- `GET /bills` - List bills
- `GET /bills/:id` - Get bill details
- `PUT /bills/:id/items` - Update items
- `DELETE /bills/:id` - Delete bill

## 📝 Database Schema

### User
```javascript
{
  email: String,
  password: String (hashed),
  name: String,
  preferences: {
    drinks_alcohol: Boolean,
    eats_meat: Boolean,
    meat_types: [String]
  },
  friends: [ObjectId]
}
```

### Bill
```javascript
{
  uploadedBy: ObjectId,
  imageUrl: String,
  participants: [ObjectId],
  items: [{
    name: String,
    quantity: Number,
    cost: Number
  }],
  totalAmount: Number,
  status: String,
  restaurant: {
    name: String,
    type: String
  }
}
```

## 🐛 Common Issues

**Backend won't start:**
- Check MongoDB is running: `mongod`
- Verify `.env` file exists and has correct values

**iOS app can't connect:**
- Ensure backend is running
- Check baseURL in APIService.swift
- For physical device, use computer's IP address

**Images won't upload:**
- Check uploads/ directory permissions
- Verify UPLOAD_DIR in .env

## 📚 Next Steps

1. Test all features end-to-end
2. Add more test users
3. Upload sample bills
4. Prepare for Phase 2 AI integration

## 🆘 Support

For issues or questions, check:
- README.md for detailed documentation
- Backend API documentation in backend/README.md
- iOS app setup in ios-app/README.md

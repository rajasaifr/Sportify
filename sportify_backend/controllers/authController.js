import admin from '../firebase/firebaseConfig.js';

export const signup = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    // Validate input
    if (!email || !password || !name) {
      return res.status(400).json({ 
        error: "Email, password, and name are required" 
      });
    }

    // Validate email format
    if (!email.includes('@')) {
      return res.status(400).json({ 
        error: "Please enter a valid email address" 
      });
    }

    // Validate password length
    if (password.length < 6) {
      return res.status(400).json({ 
        error: "Password must be at least 6 characters long" 
      });
    }

    // Validate name
    if (name.length < 2) {
      return res.status(400).json({ 
        error: "Name must be at least 2 characters long" 
      });
    }

    console.log("✅ Input validation passed");

    // 1. Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    console.log("✅ User created in Auth:", userRecord.uid);

    // 2. Create user profile in Firestore
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      uid: userRecord.uid,
      email: email,
      displayName: name,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ User profile created in Firestore:", userRecord.uid);

    res.status(201).json({
      message: "User created successfully",
      uid: userRecord.uid,
      email: userRecord.email,
      name: userRecord.displayName,
    });
  } catch (err) {
    console.error("❌ Signup error:", err);
    
    // Handle specific Firebase errors
    if (err.code === 'auth/email-already-exists') {
      return res.status(400).json({ error: "Email already exists" });
    } else if (err.code === 'auth/invalid-email') {
      return res.status(400).json({ error: "Invalid email address" });
    } else if (err.code === 'auth/invalid-password') {
      return res.status(400).json({ error: "Password must be at least 6 characters" });
    }
    
    res.status(400).json({ 
      error: err.message || "Failed to create user" 
    });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ 
        error: "Email and password are required" 
      });
    }

    // Validate email format
    if (!email.includes('@')) {
      return res.status(400).json({ 
        error: "Please enter a valid email address" 
      });
    }

    console.log("✅ Login validation passed for:", email);

    // For backend login with Firebase Admin, we need to:
    // 1. Verify the user exists and get their UID
    // 2. Create a custom token for client-side authentication
    
    // Get user by email
    const userRecord = await admin.auth().getUserByEmail(email);
    
    if (!userRecord) {
      return res.status(400).json({ 
        error: "Invalid email or password" 
      });
    }

    console.log("✅ User found:", userRecord.uid);

    // Note: Firebase Admin cannot verify passwords directly
    // The actual password verification happens client-side with Firebase Auth
    // Here we just verify the user exists and return a success message
    
    res.status(200).json({
      message: "Login successful - use Firebase Auth SDK in Flutter for actual authentication",
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        name: userRecord.displayName,
      }
    });

  } catch (err) {
    console.error("❌ Login error:", err);
    
    // Handle specific Firebase errors
    if (err.code === 'auth/user-not-found') {
      return res.status(400).json({ error: "Invalid email or password" });
    } else if (err.code === 'auth/invalid-email') {
      return res.status(400).json({ error: "Invalid email address" });
    }
    
    res.status(400).json({ 
      error: err.message || "Failed to login" 
    });
  }
};
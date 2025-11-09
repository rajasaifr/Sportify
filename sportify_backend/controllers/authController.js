import admin from '../firebase/firebaseConfig.js';

export const signup = async (req, res) => {
  try {
    const { email, password, name } = req.body;

    console.log('📧 Signup attempt for:', email);

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

    let userRecord;
    
    try {
      // 1. Create user in Firebase Auth
      userRecord = await admin.auth().createUser({
        email,
        password,
        displayName: name,
      });
      console.log("✅ User created in Auth:", userRecord.uid);
      
    } catch (authError) {
      // Handle the case where user might already exist
      if (authError.code === 'auth/email-already-exists' || authError.code === 'auth/email-already-in-use') {
        console.log('⚠️ Email already exists in Firebase Auth');
        
        // Try to get the existing user
        try {
          userRecord = await admin.auth().getUserByEmail(email);
          console.log('✅ Found existing user:', userRecord.uid);
          
          // Check if user profile exists in Firestore
          const userDoc = await admin.firestore().collection('users').doc(userRecord.uid).get();
          
          if (userDoc.exists) {
            return res.status(400).json({ 
              error: "Email already registered. Please sign in instead." 
            });
          }
          
          // User exists in Auth but not in Firestore - continue to create profile
          console.log('🔄 Creating Firestore profile for existing Auth user');
          
        } catch (getUserError) {
          console.error('❌ Error getting existing user:', getUserError);
          return res.status(400).json({ 
            error: "Account may be processing. Please try again in a moment." 
          });
        }
      } else {
        // Re-throw other auth errors
        throw authError;
      }
    }

    // 2. Create user profile in Firestore
    try {
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

    } catch (firestoreError) {
      console.error("❌ Firestore error:", firestoreError);
      
      // Even if Firestore fails, the Auth user was created
      res.status(201).json({
        message: "User authentication created, but profile setup incomplete",
        uid: userRecord.uid,
        email: userRecord.email,
        warning: "Please complete your profile later"
      });
    }

  } catch (err) {
    console.error("❌ Signup error:", err);
    
    // Handle specific Firebase errors
    if (err.code === 'auth/email-already-exists' || err.code === 'auth/email-already-in-use') {
      return res.status(400).json({ 
        error: "This email is already registered. Please sign in instead." 
      });
    } else if (err.code === 'auth/invalid-email') {
      return res.status(400).json({ 
        error: "Invalid email address format" 
      });
    } else if (err.code === 'auth/invalid-password') {
      return res.status(400).json({ 
        error: "Password must be at least 6 characters long" 
      });
    } else if (err.code === 'auth/operation-not-allowed') {
      return res.status(400).json({ 
        error: "Email/password accounts are not enabled. Check Firebase Auth settings." 
      });
    } else if (err.code === 'auth/too-many-requests') {
      return res.status(400).json({ 
        error: "Too many attempts. Please try again later." 
      });
    } else if (err.code === 'auth/weak-password') {
      return res.status(400).json({ 
        error: "Password is too weak. Please choose a stronger password." 
      });
    }
    
    res.status(400).json({ 
      error: err.message || "Failed to create user" 
    });
  }
};

export const login = async (req, res) => {
  try {
    const { idToken } = req.body; // CHANGED: Expect ID token from Flutter

    // Validate input
    if (!idToken) {
      return res.status(400).json({ 
        error: "ID token is required. Please sign in with Firebase Auth first." 
      });
    }

    console.log("🔐 Login verification for token");

    // Verify the ID token from Flutter Firebase Auth
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    console.log("✅ Token verified for user:", decodedToken.uid);

    // Get additional user data
    const userRecord = await admin.auth().getUser(decodedToken.uid);

    res.status(200).json({
      message: "Login successful",
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        name: userRecord.displayName,
      }
    });

  } catch (err) {
    console.error("❌ Login error:", err);
    
    // Handle specific Firebase errors
    if (err.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        error: "Session expired. Please sign in again." 
      });
    } else if (err.code === 'auth/id-token-revoked') {
      return res.status(401).json({ 
        error: "Session revoked. Please sign in again." 
      });
    } else if (err.code === 'auth/invalid-id-token') {
      return res.status(401).json({ 
        error: "Invalid session. Please sign in again." 
      });
    } else if (err.code === 'auth/user-not-found') {
      return res.status(400).json({ 
        error: "User not found. Please sign up first." 
      });
    }
    
    res.status(401).json({ 
      error: "Authentication failed. Please try again." 
    });
  }
};

// Add this new endpoint to check user status
export const checkUser = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ 
        error: "Email is required" 
      });
    }

    console.log('🔍 Checking user status for:', email);

    try {
      // Check if user exists in Firebase Auth
      const userRecord = await admin.auth().getUserByEmail(email);
      console.log('✅ User found in Auth:', userRecord.uid);

      // Check if user exists in Firestore
      const userDoc = await admin.firestore().collection('users').doc(userRecord.uid).get();
      
      res.status(200).json({
        existsInAuth: true,
        existsInFirestore: userDoc.exists,
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName,
      });

    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        res.status(200).json({
          existsInAuth: false,
          existsInFirestore: false,
          message: "User not found"
        });
      } else {
        throw error;
      }
    }

  } catch (err) {
    console.error('❌ Check user error:', err);
    res.status(500).json({ 
      error: "Failed to check user status" 
    });
  }
};
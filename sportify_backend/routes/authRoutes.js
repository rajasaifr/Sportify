import express from "express";
import { signup, login, checkUser } from "../controllers/authController.js";

const router = express.Router();

router.post("/signup", signup);
router.post("/login", login);
router.post("/check-user", checkUser); // Add this

export default router;
import express from 'express';
import * as authController from '../controllers/authController.js';
import rateLimit from 'express-rate-limit';

const router = express.Router();

const authMax = process.env.NODE_ENV === 'test' ? 1000 : 10;
const mutateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: authMax,
  standardHeaders: true,
  legacyHeaders: false,
});

router.use(mutateLimiter);

router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/refresh', authController.refresh);
router.post('/logout', authController.logout);

export default router;
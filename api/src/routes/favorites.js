import express from 'express';
import auth from '../middlewares/auth.js';
import rateLimit from 'express-rate-limit';
import * as favoriteController from '../controllers/favoriteController.js';

const router = express.Router();

const mutateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 30,
  keyGenerator: (req) => req.userId,
  standardHeaders: true,
});

router.use(auth);

router.get('/', favoriteController.getFavorites);
router.post('/', mutateLimiter, favoriteController.addFavorite);
router.delete('/:id', mutateLimiter, favoriteController.deleteFavorite);

export default router;
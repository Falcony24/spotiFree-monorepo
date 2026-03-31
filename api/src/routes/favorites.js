import express from 'express';
import auth from '../middlewares/auth.js';
import * as favoriteController from '../controllers/favoriteController.js';

const router = express.Router();

router.use(auth);

router.get('/', favoriteController.getFavorites);
router.post('/', favoriteController.addFavorite);
router.delete('/:id', favoriteController.deleteFavorite);

export default router;
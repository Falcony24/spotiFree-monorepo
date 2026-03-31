import express from 'express';
import auth from '../middlewares/auth.js';
import * as userController from '../controllers/userController.js';

const router = express.Router();

router.use(auth); 

router.get('', userController.getCurrentUser);
router.put('', userController.updateProfile); 
router.delete('', userController.deleteAccount);

export default router;
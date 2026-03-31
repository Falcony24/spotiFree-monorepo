import { User } from '../models/index.js';
import { Op } from 'sequelize';
import sequelize from '../config/database.js'; 

export const getCurrentUser = async (req, res, next) => {
  try {
    
    const user = await req.user.toJSON(); 
    delete user.password_hash;
    res.json(user);
  } catch (err) {
    next(err);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const { display_name, email } = req.body;
    const user = req.user;
    if (display_name !== undefined) user.display_name = display_name;
    if (email !== undefined) user.email = email;
    await user.save();
    const userJson = user.toJSON();
    delete userJson.password_hash;
    res.json(userJson);
  } catch (err) {
    next(err);
  }
};

export const deleteAccount = async (req, res, next) => {
  try {
    const user = req.user;
    await user.destroy();
    res.status(204).send();
  } catch (err) {
    next(err);
  }
};
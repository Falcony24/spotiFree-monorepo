import { User } from '../models/index.js';
import { Op } from 'sequelize';
import sequelize from '../config/database.js'; 

export const getCurrentUser = async (req, res, next) => {
  try {
    const user = req.user;
    res.json({
      id: user.gid,
      username: user.username,
      created_at: user.created_at,
      updated_at: user.updated_at
    });
  } catch (err) {
    next(err);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const { username } = req.body;  
    const user = req.user;
    if (username !== undefined) user.username = username;
    await user.save();
    res.json({
      id: user.gid,
      username: user.username,
      created_at: user.created_at,
      updated_at: user.updated_at
    });
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
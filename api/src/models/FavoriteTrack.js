import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';
import { Recording } from '../models/musicbrainz/index.js';
import User from './User.js';

const FavoriteTrack = sequelize.define('FavoriteTrack', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: User, key: 'id' }
  },
  track_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: Recording, key: 'id' } 
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'favorite_tracks',
  timestamps: false,
  underscored: true,
  indexes: [
    { fields: ['user_id', 'track_id'], unique: true }
  ]
});

export default FavoriteTrack;
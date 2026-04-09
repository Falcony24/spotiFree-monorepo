import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';
import { Artist } from '../models/musicbrainz/index.js';
import User from './User.js'; 

const FavoriteArtist = sequelize.define('FavoriteArtist', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true
  },
  gid: { 
    type: DataTypes.UUID, 
    defaultValue: DataTypes.UUIDV4, 
    allowNull: false, 
    unique: true 
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: User,        
      key: 'id'
    }
  },
  artist_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: Artist,      
      key: 'id'
    }
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'favorite_artists',
  timestamps: false,
  underscored: true,
  indexes: [
    { fields: ['user_id', 'artist_id'], unique: true }
  ]
});

export default FavoriteArtist;
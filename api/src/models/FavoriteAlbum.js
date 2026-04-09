import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';
import { ReleaseGroup } from '../models/musicbrainz/index.js';
import User from './User.js';

const FavoriteAlbum = sequelize.define('FavoriteAlbum', {
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
    references: { model: User, key: 'id' }
  },
  album_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: { model: ReleaseGroup, key: 'id' } 
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'favorite_albums',
  timestamps: false,
  underscored: true,
  indexes: [
    { fields: ['user_id', 'album_id'], unique: true }
  ]
});

export default FavoriteAlbum;
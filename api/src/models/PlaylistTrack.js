import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const PlaylistTrack = sequelize.define('PlaylistTrack', {
  id: { 
    type: DataTypes.INTEGER, 
    primaryKey: true, 
    autoIncrement: true 
  },
  gid: { 
    type: DataTypes.UUID, 
    defaultValue: DataTypes.UUIDV4, 
    allowNull: false, 
    unique: true 
  },
  playlist_id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    references: { model: 'playlists', key: 'id' },
    onDelete: 'CASCADE'
  },
  track_mbid: {
    type: DataTypes.UUID,
    primaryKey: true
  },
  position: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  added_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'playlist_tracks',
  timestamps: true,
  createdAt: 'added_at',
  updatedAt: false,
  indexes: [{ unique: true, fields: ['playlist_id', 'track_mbid'] }]
});

export default PlaylistTrack;
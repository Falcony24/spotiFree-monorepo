import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const DownloadTask = sequelize.define('DownloadTask', {
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
  track_mbid: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true
  },
  status: {
    type: DataTypes.ENUM('pending', 'processing', 'completed', 'failed'),
    defaultValue: 'pending'
  },
  source_url: {
    type: DataTypes.STRING(255)
  },
  retries: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  created_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_at: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'download_tasks',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

export default DownloadTask;
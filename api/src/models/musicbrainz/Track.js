import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const Track = sequelize.define('Track', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  gid: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true
  },
  recording: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  medium: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  position: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  number: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false
  },
  artist_credit: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  length: {
    type: DataTypes.INTEGER,
    validate: { min: 0 }
  },
  edits_pending: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  last_updated: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  is_data_track: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  }
}, {
  tableName: 'track',
  timestamps: false,
  indexes: [
    { fields: ['gid'] },
    { fields: ['recording'] },
    { fields: ['medium'] },
    { fields: ['artist_credit'] }
  ]
});

export default Track;
import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const Medium = sequelize.define('Medium', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  release: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  position: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  format: DataTypes.INTEGER,
  name: {
    type: DataTypes.STRING,
    defaultValue: ''
  },
  edits_pending: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  last_updated: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  track_count: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  gid: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  tableName: 'medium',
  timestamps: false,
  indexes: [
    { fields: ['gid'] },
    { fields: ['release'] }
  ]
});

export default Medium;
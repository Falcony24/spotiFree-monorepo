import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const Recording = sequelize.define('Recording', {
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
  comment: {
    type: DataTypes.STRING(255),
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
  video: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  }
}, {
  tableName: 'recording',
  timestamps: false,
  indexes: [
    { fields: ['gid'] },
    { fields: ['name'] },
    { fields: ['artist_credit'] }
  ]
});

export default Recording;
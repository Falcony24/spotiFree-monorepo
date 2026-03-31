import { DataTypes } from 'sequelize';
import sequelize from '../../config/database.js';

const ReleaseGroupTag = sequelize.define('ReleaseGroupTag', {
  release_group: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  tag: {
    type: DataTypes.INTEGER,
    primaryKey: true
  },
  count: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  last_updated: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  }
}, {
  tableName: 'release_group_tag',
  timestamps: false,
  indexes: [
    { fields: ['tag'] }
  ]
});

export default ReleaseGroupTag;
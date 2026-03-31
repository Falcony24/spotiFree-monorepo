import Artist from './Artist.js';
import ArtistCredit from './ArtistCredit.js';
import ArtistCreditName from './ArtistCreditName.js';
import ReleaseGroup from './ReleaseGroup.js';
import Release from './Release.js';
import Medium from './Medium.js';
import Recording from './Recording.js';
import Track from './Track.js';
import Tag from './Tag.js';
import ArtistTag from './ArtistTag.js';
import ReleaseGroupTag from './ReleaseGroupTag.js';
import RecordingTag from './RecordingTag.js';
import ReleaseCountry from './ReleaseCountry.js';
import ReleaseUnknownCountry from './ReleaseUnknownCountry.js';
import ReleaseMeta from './ReleaseMeta.js';
// import ArtistGidRedirect from './ArtistGidRedirect.js';
// import ReleaseGroupGidRedirect from './ReleaseGroupGidRedirect.js';
// import RecordingGidRedirect from './RecordingGidRedirect.js';

Recording.hasMany(ArtistCreditName, { foreignKey: 'artist_credit', sourceKey: 'artist_credit', as: 'artistCreditNames' });
ArtistCreditName.belongsTo(ArtistCredit, { foreignKey: 'artist_credit' });
ArtistCreditName.belongsTo(Artist, { foreignKey: 'artist', as: 'Artist' });
Track.belongsTo(Recording, { foreignKey: 'recording', as: 'recordingDetail' });
ReleaseGroup.belongsTo(ArtistCredit, { foreignKey: 'artist_credit', as: 'artistCredit' });
Recording.belongsTo(ArtistCredit, { foreignKey: 'artist_credit', as: 'artistCredit' });
ArtistCredit.hasMany(ArtistCreditName, { foreignKey: 'artist_credit', as: 'artistCreditNames' });

export {
  Artist,
  ArtistCredit,
  ArtistCreditName,
  ReleaseGroup,
  Release,
  Medium,
  Recording,
  Track,
  Tag,
  ArtistTag,
  ReleaseGroupTag,
  RecordingTag,
  ReleaseCountry,
  ReleaseUnknownCountry,
  ReleaseMeta,
  // ArtistGidRedirect,
  // ReleaseGroupGidRedirect,
  // RecordingGidRedirect,
};
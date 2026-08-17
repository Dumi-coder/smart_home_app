const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json'); // Assume it doesn't exist, we can use application default credentials if we have them, or just use firebase tools.

// Or we can use the app to log the URL.

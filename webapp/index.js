// ------------------------------------------------------
// Import all required packages and files
// ------------------------------------------------------

let Pusher     = require('pusher');
let express    = require('express');
let bodyParser = require('body-parser');
let Promise    = require('bluebird');
let db         = require('sqlite');
let app        = express();

let pusher     = new Pusher(require('./config.js'));

// ------------------------------------------------------
// Set up Express
// ------------------------------------------------------

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

// ------------------------------------------------------
// Define routes and logic
// ------------------------------------------------------

app.get('/users', (req, res, next) => {
  try {
    db.all('SELECT * FROM (SELECT * FROM Users ORDER BY updated_at DESC) ORDER BY position ASC')
      .then(result => res.json(result))
  } catch (err) {
    next(err)
  }
})

app.post("/add", (req, res, next) => {
  try {
    let payload = {name:req.body.name, deviceId: req.body.deviceId}

    db.run("INSERT INTO Users (name, position) VALUES (?, (SELECT MAX(id) + 1 FROM Users))", payload.name).then(query => {
      payload.id = query.stmt.lastID
      pusher.trigger('userslist', 'addUser', payload)
      return res.json(payload)
    })
  } catch (err) {
    next(err)
  }
})

app.post("/delete", (req, res, next) => {
  try {
    let payload = {id:parseInt(req.body.id), index:parseInt(req.body.index), deviceId: req.body.deviceId}

    db.run(`DELETE FROM Users WHERE id=${payload.id}`).then(query => {
      pusher.trigger('userslist', 'removeUser', payload)
      return res.json(payload)
    })
  } catch (err) {
    next(err)
  }
})

app.post("/move", (req, res, next) => {
  try {
    let payload = {
      deviceId: req.body.deviceId,
      src: parseInt(req.body.src),
      dest: parseInt(req.body.dest),
      src_id: parseInt(req.body.src_id),
      dest_id: parseInt(req.body.dest_id),
    }

    db.run(`UPDATE Users SET position=${payload.dest + 1}, updated_at=CURRENT_TIMESTAMP WHERE id=${payload.src_id}`).then(query => {
      pusher.trigger('userslist', 'moveUser', payload)
      res.json(payload)
    })
  } catch (err) {
    next(err)
  }
})

app.get('/', (req, res) => {
  res.json("It works!");
});


// ------------------------------------------------------
// Catch errors
// ------------------------------------------------------

app.use((req, res, next) => {
    let err = new Error('Not Found');
    err.status = 404;
    next(err);
});


// ------------------------------------------------------
// Start application
// ------------------------------------------------------

Promise.resolve()
  .then(() => db.open('./database.sqlite', { Promise }))
  .then(() => db.migrate({ force: 'last' }))
  .catch(err => console.error(err.stack))
  .finally(() => app.listen(4000, function(){
    console.log('App listening on port 4000!')
  }));

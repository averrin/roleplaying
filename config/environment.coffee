module.exports =
  development:
    app:
      name: 'RPG Workshop'
    root: require('path').normalize(__dirname + '/..')
    db: process.env.MONGOLAB_URI || process.env.MONGOHQ_URL \
        || 'mongodb://localhost/otagai'
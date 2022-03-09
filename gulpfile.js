const gulp = require('gulp');
const { exec } = require('child_process');

gulp.task('compile', function (callback) {
    exec('truffle compile --reset', function (err, stdout, stderr) {
        console.error(stderr);
        console.log(stdout);
        callback(err);
    });
});

gulp.task('watch', function () {
    gulp.watch('contracts/**/*.sol', ['compile']);
});

gulp.task('default', function () {
    gulp.start('watch');
});


// Tests
gulp.task('test', function(callback){
    exec('truffle test --network mainnet_fork test/test-index.js', function (err, stdout, stderr) {
        console.error(stderr);
        console.log(stdout);
        callback(err)
    });
});


gulp.task('watch_tests', function(){
    gulp.watch('test/**/*.js', ['test']);
})

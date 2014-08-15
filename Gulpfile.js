var gulp = require('gulp'),
	jade = require('gulp-jade'),
	stylus = require('gulp-stylus'),
	coffee = require('gulp-coffee'),
	livereload = require('gulp-livereload'),
	atomShell = require('gulp-download-atom-shell'),
	exec = require('child_process').exec,
	spawn = require('child_process').spawn,
	fs = require('fs'),
	gutil = require('gulp-util'),
	del = require('del'),
	sourcemaps = require('gulp-sourcemaps'),
	concat = require('gulp-concat'),
	uglify = require('gulp-uglify'),
	amdOptimize = require('amd-optimize'),
	args = require('yargs').argv,
	gif = require('gulp-if'),
	output, prog;

gulp.task('build:css', ['clean:style'], function () {
	return gulp.src('src/**/*.styl')
	.pipe(stylus().on('error', function(err) {
		exit(new gutil.PluginError('Stylus', err));
	}))
	.pipe(gulp.dest('bin/resources/app/'))
	.pipe(livereload({ auto: false }));
});

gulp.task('build:html', ['clean:html'], function () {
	return gulp.src('src/**/*.jade')
	.pipe(jade().on('error', function(err) {
		exit(gutil.PluginError('Jade', err));
	}))
	.pipe(gulp.dest('bin/resources/app/'))
	.pipe(livereload({ auto: false }));
});

gulp.task('build:js', ['clean:script'], function () {
	return gulp.src('src/**/*.coffee')
	.pipe(gif(!args.optimize, sourcemaps.init()))
	.pipe(coffee().on('error', function(err) {
		exit(new gutil.PluginError('CoffeeScript', err));
	}))
	.pipe(gif(!args.optimize, sourcemaps.write()))
	.pipe(gif(args.optimize, gulp.dest('.tmp/'), gulp.dest('bin/resources/app/')))
	.pipe(livereload({ auto: false }));
});

gulp.task('build:img', ['clean:img'], function () {
	return gulp.src('src/**/*.png')
	.pipe(gulp.dest('bin/resources/app/'))
	.pipe(livereload({ auto: false }));
});

gulp.task('build:shell', function(cb){
    atomShell({
      version: '0.15.6',
      outputDir: 'bin'
    }, cb);
});

gulp.task('build:config', function(){
	return gulp.src('app/**/*').pipe(gulp.dest('bin/resources/app/'));
});

gulp.task('build:bower', ['clean:bower'], function () {
	return gulp.src(['bower_components/requirejs/require.js', 'bower_components/jquery/dist/jquery.min.js', 'bower_components/jquery/dist/jquery.min.map', 'bower_components/coffeescript/extras/coffee-script.js'])
	.pipe(gif(function(file) {return args.optimize && file.relative !== 'require.js';}, gulp.dest('.tmp/js/bower/'), gulp.dest('bin/resources/app/js/bower/')))
	.pipe(livereload({ auto: false }));
});

gulp.task('watch', function() {
	livereload.listen();
	gulp.watch('src/**/*.styl', ['build:css']);
	if(args.optimize) {
		gulp.watch('src/**/*.coffee', ['build:move']);
	} else {
		gulp.watch('src/**/*.coffee', ['build:js']);
	}
	gulp.watch('src/**/*.jade', ['build:html']);
	gulp.watch('bower_components/**/*.js', ['build:bower']);
	gulp.watch('app/*', ['run']);
});

gulp.task('run', ['build'], function() {
	if(prog) {
		prog.kill();
		prog = null;
	}
	prog = exec(__dirname + '/bin/atom.exe --dev');
	prog.stdout.on('data', function(data) {
		gutil.log(gutil.colors.blue(data));
	});
	prog.stderr.on('data', function(data) {
		gutil.log(gutil.colors.red(data));
	});
});

function exit(err) {
	console.error(err);
	if(prog) {
		prog.kill();
		prog = null;
	}
	process.exit(err.code);
}

process.on('uncaughtException', exit);

gulp.task("build:rjs", ['build:js', 'build:bower'], function(cb) {
	exec('r.js.cmd -o ' + __dirname + '/build.js', function(err) {
		if(err)
			cb(new gutil.PluginError('r.js', err));
		else
			cb();
	}).stdout.on('data', function(data) {
		gutil.log(gutil.colors.green(data));
	});
});

gulp.task('build:move', ['build:rjs'], function() {
	return gulp.src('dist/**/*')
	.pipe(gulp.dest('bin/resources/app/js/'))
	.pipe(livereload({ auto: false }));
});

gulp.task('clean', function (cb) {
	del(['bin/**', '.tmp'], cb);
});

gulp.task('clean:app', function (cb) {
	del(['bin/resources/app/**'], cb);
});

gulp.task('clean:html', function (cb) {
	del(['bin/resources/app/**/*.html'], cb);
});

gulp.task('clean:style', function (cb) {
	del(['bin/resources/app/**/*.css'], cb);
});

gulp.task('clean:script', function (cb) {
	del(['bin/resources/app/**/*.js', '!bin/resources/app/js/bower/**/*'], cb);
});

gulp.task('clean:img', function (cb) {
	del(['bin/resources/app/**/*.png'], cb);
});

gulp.task('clean:bower', function (cb) {
	del(['bin/resources/app/js/bower/**/*'], cb);
});

if(args.optimize) {
	gulp.task('build', ['build:html', 'build:css', 'build:move', 'build:img', 'build:config'], function(cb) {
		del(['.tmp', 'dist'], cb);
	})
} else {
	gulp.task('build', ['build:html', 'build:css', 'build:js', 'build:img', 'build:bower', 'build:config']);
}

gulp.task('default', ['build', 'run', 'watch']);

const fs = require('fs');
const { spawn } = require('child_process');
const path = require('path');
const mime = require('mime-types');
const serveStatic = require('serve-static');
const express = require('express');

const playlist = {"images":["1.jpg","image.png"],"interval":5000,"lastUpdated":"2025-06-19T04:58:27.381Z"};
const imagesDir = path.join(__dirname, 'public', 'images');
let currentIndex = 0;

function closeCurrentWindow() {
  if (process.platform === 'win32') {
    // Можно попробовать spawn для taskkill, но если не критично, можно не поддерживать закрытие на Windows
    spawn('taskkill', ['/f', '/im', 'ms-photos.exe']);
    spawn('taskkill', ['/f', '/im', 'rundll32.exe']);
    spawn('taskkill', ['/f', '/im', 'explorer.exe', '/fi', 'WINDOWTITLE eq *Photo*']);
  } else {
    spawn('pkill', ['-f', 'eog|feh|display|gwenview']);
  }
}

function showNextImage() {
  if (currentIndex >= playlist.images.length) {
    currentIndex = 0;
  }
  // Фильтрация имени файла
  const safeFilename = path.basename(playlist.images[currentIndex]);
  if (!/^[\w.\-]+$/.test(safeFilename) || !/\.(jpg|png|gif|webp)$/i.test(safeFilename)) {
    currentIndex++;
    setTimeout(showNextImage, playlist.interval);
    return;
  }
  const imagePath = path.join(imagesDir, safeFilename);
  closeCurrentWindow();
  setTimeout(() => {
    if (process.platform === 'win32') {
      // spawn для Windows запуска через start
      spawn('cmd', ['/c', 'start', '', imagePath], { detached: true, stdio: 'ignore' });
    } else {
      // Используем spawn для feh/eog/xdg-open
      const feh = spawn('feh', ['-F', '-Z', imagePath], { detached: true, stdio: 'ignore' });
      feh.on('error', () => {
        const eog = spawn('eog', ['-f', imagePath], { detached: true, stdio: 'ignore' });
        eog.on('error', () => {
          spawn('xdg-open', [imagePath], { detached: true, stdio: 'ignore' });
        });
        eog.unref();
      });
      feh.unref();
    }
  }, 500);
  currentIndex++;
  setTimeout(showNextImage, playlist.interval);
}
showNextImage();

const app = express();

app.use('/images', serveStatic(path.join(__dirname, 'public', 'images'), {
  setHeaders: (res, path) => {
    res.setHeader('Content-Type', mime.lookup(path) || 'application/octet-stream');
  }
}));

app.use(express.static('public'));
      
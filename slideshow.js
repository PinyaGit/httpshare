const fs = require('fs');
const { exec } = require('child_process');
const path = require('path');
const mime = require('mime-types');
const serveStatic = require('serve-static');
const express = require('express');

const playlist = {"images":["1.jpg","image.png"],"interval":5000,"lastUpdated":"2025-06-19T04:58:27.381Z"};
const imagesDir = path.join(__dirname, 'public', 'images');
let currentIndex = 0;

function closeCurrentWindow() {
  if (process.platform === 'win32') {
    exec('taskkill /f /im ms-photos.exe 2>nul', () => {});
    exec('taskkill /f /im rundll32.exe 2>nul', () => {});
    exec('taskkill /f /im explorer.exe /fi "WINDOWTITLE eq *Photo*" 2>nul', () => {});
  } else {
    exec('pkill -f "eog|feh|display|gwenview" 2>/dev/null', () => {});
  }
}

function showNextImage() {
  if (currentIndex >= playlist.images.length) {
    currentIndex = 0;
  }
  const imagePath = path.join(imagesDir, playlist.images[currentIndex]);
  closeCurrentWindow();
  setTimeout(() => {
    if (process.platform === 'win32') {
      exec('rundll32 shimgvw.dll,ImageView_Fullscreen "' + imagePath + '"', (err) => {
        if (err) {
          exec('start "" "' + imagePath + '"');
        }
      });
    } else {
      exec('feh -F -Z "' + imagePath + '"', (err) => {
        if (err) {
          exec('eog -f "' + imagePath + '"', (err) => {
            if (err) {
              exec('xdg-open "' + imagePath + '"');
            }
          });
        }
      });
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
      
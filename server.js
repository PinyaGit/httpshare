const fs = require('fs'); // <- Добавлено
const express = require('express');
const path = require('path');
const { spawn } = require('child_process');
const cors = require('cors');
const multer = require('multer');

const app = express();
const port = 8080;

// Настройка Multer для сохранения файлов
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dest = path.join(__dirname, 'public', 'images');
    // Создаём папку, если её нет
    fs.mkdir(dest, { recursive: true }, (err) => {
      if (err) {
        console.error('Ошибка создания папки:', err);
        return cb(err);
      }
      cb(null, dest);
    });
  },
  filename: function (req, file, cb) {
    // Используем оригинальное имя файла
    cb(null, file.originalname);
  }
});

const upload = multer({ storage: storage });

app.use(cors());
app.use(express.static('public'));
app.use(express.json());

// API: Список картинок
app.get('/api/images', (req, res) => {
  const imagesDir = path.join(__dirname, 'public', 'images');
  
  // Проверяем, существует ли папка
  if (!fs.existsSync(imagesDir)) {
    return res.json([]); // Возвращаем пустой массив, если папки нет
  }

  fs.readdir(imagesDir, (err, files) => {
    if (err) return res.json([]);
    const images = files.filter(file => /\.(jpg|png|gif|webp)$/i.test(file));
    res.json(images);
  });
});

// API: Открыть картинку на этом ПК
app.get('/api/open-image', (req, res) => {
  const { filename, token } = req.query;
  if (token !== 'SECRET123') return res.status(403).send('Доступ запрещён');

  // Фильтрация имени файла
  const safeFilename = path.basename(filename);
  if (!/^[\w.\-]+$/.test(safeFilename) || !/\.(jpg|png|gif|webp)$/i.test(safeFilename)) {
    return res.status(400).send('Недопустимое имя файла');
  }
  const imagePath = path.join(__dirname, 'public', 'images', safeFilename);

  if (process.platform !== 'linux') {
    return res.status(400).send('Открытие изображений поддерживается только на Ubuntu/Linux');
  }

  // Останавливаем старые процессы feh перед открытием нового изображения
  const pkill = spawn('pkill', ['-f', 'feh']);
  pkill.on('close', () => {
    // Открываем изображение через feh в полноэкранном режиме (spawn безопаснее)
    const feh = spawn('feh', ['-F', '-Z', imagePath], { detached: true, stdio: 'ignore' });
    feh.unref();
    res.send(`Картинка ${safeFilename} открыта через feh на этом ПК!`);
  });
});

// API: Загрузить картинку
app.post('/api/upload', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Файл не был загружен' });
  }
  res.json({ success: true, message: `Файл ${req.file.originalname} загружен` });
});

// API: Удалить картинку
app.post('/api/delete-image', (req, res) => {
  const { filename } = req.body;
  if (!filename) {
    return res.status(400).json({ error: 'Имя файла не указано' });
  }

  // Важная проверка безопасности: убеждаемся, что путь не выходит за пределы папки /images
  const imagePath = path.join(__dirname, 'public', 'images', filename);
  const imagesDir = path.join(__dirname, 'public', 'images');
  if (path.dirname(imagePath) !== imagesDir) {
    return res.status(403).json({ error: 'Недопустимый путь к файлу' });
  }

  fs.unlink(imagePath, (err) => {
    if (err) {
      console.error(`Ошибка удаления файла ${filename}:`, err);
      return res.status(500).json({ error: `Ошибка удаления файла: ${err.message}` });
    }
    res.json({ success: true, message: `Файл ${filename} удалён` });
  });
});

// API: Сохранить плейлист
app.post('/api/playlist', (req, res) => {
  const { images, interval } = req.body;
  const playlistPath = path.join(__dirname, 'playlist.json');
  
  const playlist = {
    images: images || [],
    interval: interval || 5000, // 5 секунд по умолчанию
    lastUpdated: new Date().toISOString()
  };
  
  fs.writeFile(playlistPath, JSON.stringify(playlist, null, 2), (err) => {
    if (err) return res.status(500).json({ error: 'Ошибка сохранения плейлиста' });
    res.json({ success: true, message: 'Плейлист сохранен' });
  });
});

// API: Загрузить плейлист
app.get('/api/playlist', (req, res) => {
  const playlistPath = path.join(__dirname, 'playlist.json');
  
  if (!fs.existsSync(playlistPath)) {
    return res.json({ images: [], interval: 5000 });
  }
  
  fs.readFile(playlistPath, 'utf8', (err, data) => {
    if (err) return res.json({ images: [], interval: 5000 });
    try {
      const playlist = JSON.parse(data);
      res.json(playlist);
    } catch (e) {
      res.json({ images: [], interval: 5000 });
    }
  });
});

// API: Запустить слайдшоу
app.post('/api/slideshow/start', (req, res) => {
  const { token } = req.query;
  if (token !== 'SECRET123') return res.status(403).send('Доступ запрещён');

  if (process.platform !== 'linux') {
    return res.status(400).json({ error: 'Слайдшоу поддерживается только на Ubuntu/Linux' });
  }

  const playlistPath = path.join(__dirname, 'playlist.json');
  if (!fs.existsSync(playlistPath)) {
    return res.status(400).json({ error: 'Плейлист не найден' });
  }
  fs.readFile(playlistPath, 'utf8', (err, data) => {
    if (err) return res.status(500).json({ error: 'Ошибка чтения плейлиста' });
    try {
      const playlist = JSON.parse(data);
      if (!playlist.images || playlist.images.length === 0) {
        return res.status(400).json({ error: 'Плейлист пуст' });
      }
      // Формируем список файлов для feh
      const imagesDir = path.join(__dirname, 'public', 'images');
      const imageFiles = playlist.images.map(img => {
        const safeImg = path.basename(img);
        if (!/^[\w.\-]+$/.test(safeImg) || !/\.(jpg|png|gif|webp)$/i.test(safeImg)) return null;
        return path.join(imagesDir, safeImg);
      }).filter(Boolean);
      if (imageFiles.length === 0) {
        return res.status(400).json({ error: 'Нет валидных файлов для слайдшоу' });
      }
      const delay = Math.max(1, Math.round((playlist.interval || 5000) / 1000)); // feh требует секунды, минимум 1
      // Останавливаем старые процессы feh
      const pkill = spawn('pkill', ['-f', 'feh']);
      pkill.on('close', () => {
        // Запускаем feh с плейлистом через spawn
        const feh = spawn('feh', ['-F', '-Z', '-D', String(delay), ...imageFiles], { detached: true, stdio: 'ignore' });
        feh.unref();
        res.json({ success: true, message: 'Слайдшоу запущено через feh' });
      });
    } catch (e) {
      res.status(500).json({ error: 'Ошибка парсинга плейлиста' });
    }
  });
});

// API: Остановить слайдшоу
app.post('/api/slideshow/stop', (req, res) => {
  const { token } = req.query;
  if (token !== 'SECRET123') return res.status(403).send('Доступ запрещён');

  if (process.platform !== 'linux') {
    return res.status(400).json({ error: 'Остановка слайдшоу поддерживается только на Ubuntu/Linux' });
  }

  // Останавливаем все процессы feh
  const pkill = spawn('pkill', ['-f', 'feh']);
  pkill.on('close', () => {
    res.json({ success: true, message: 'Слайдшоу остановлено (все окна feh закрыты)' });
  });
});

app.listen(port, () => {
  console.log(`Сервер ПК запущен на http://localhost:${port}`);
});
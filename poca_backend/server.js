const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);

const io = new Server(server, { 
  cors: { origin: "*", methods: ["GET", "POST"] } 
});

app.use(express.json());

let waitingQueue = [];

io.on('connection', (socket) => {
  console.log(`[+] User connected: ${socket.id}`);

  socket.on('find_match', (userData) => {
    socket.userData = { id: socket.id, ...userData };
    console.log(`[*] Match Request from ${socket.id}:`, userData);

    // ১. কিউতে অন্য কেউ থাকলে জেন্ডার ফিল্টারিং (অথবা টেস্টের জন্য যেকোন ইউজার)
    const matchIndex = waitingQueue.findIndex(u => u.id !== socket.id);

    if (matchIndex !== -1) {
      const partner = waitingQueue.splice(matchIndex, 1)[0];
      const roomName = `poca_room_${Date.now()}`;

      // দুই ইউজারকে একই রুমে যুক্ত করা
      socket.join(roomName);
      partner.join(roomName);

      // ২ জনকেই match_found ইভেন্ট পাঠানো
      io.to(roomName).emit('match_found', { 
        channelName: roomName,
        partnerId: partner.id
      });

      console.log(`[!] MATCH SUCCESS: ${socket.id} <--> ${partner.id} in Room: ${roomName}`);
    } else {
      // কেউ না থাকলে ওয়েটিং লিস্টে রাখা
      if (!waitingQueue.some(u => u.id === socket.id)) {
        waitingQueue.push(socket);
      }
      console.log(`[-] Waiting queue length: ${waitingQueue.length}`);
    }
  });

  socket.on('cancel_match', () => {
    waitingQueue = waitingQueue.filter(u => u.id !== socket.id);
    console.log(`[-] Cancelled by: ${socket.id}`);
  });

  socket.on('disconnect', () => {
    waitingQueue = waitingQueue.filter(u => u.id !== socket.id);
    console.log(`[x] Disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

//----------Main poca app------------------------------

// const express = require('express');
// const http = require('http');
// const { Server } = require('socket.io');

// const app = express();
// const server = http.createServer(app);
// const io = new Server(server, { cors: { origin: "*" } });

// // ফিল্টারিংয়ের জন্য ওয়েটিং কিউ (Queue)
// let waitingQueue = [];

// io.on('connection', (socket) => {
//   console.log('User connected:', socket.id);

//   // ফিল্টার অনুযায়ী ম্যাচ খোঁজা (gender: "male"/"female", targetGender: "female"/"male")
//   socket.on('find_match', (userData) => {
//     socket.userData = { id: socket.id, ...userData };

//     // পছন্দের জেন্ডারের সাথে ম্যাচ খোঁজা
//     const matchIndex = waitingQueue.findIndex(u => 
//       u.userData.gender === userData.targetGender && 
//       (u.userData.targetGender === 'any' || u.userData.targetGender === userData.gender)
//     );

//     if (matchIndex !== -1) {
//       const partner = waitingQueue.splice(matchIndex, 1)[0];
//       const roomName = `room_${partner.id}_${socket.id}`;

//       socket.join(roomName);
//       partner.join(roomName);

//       // দুই ইউজারকেই রুমে জয়েন করানো
//       io.to(roomName).emit('match_found', { 
//         channelName: roomName,
//         partnerId: partner.id 
//       });

//       console.log(`Matched ${socket.id} with ${partner.id}`);
//     } else {
//       waitingQueue.push(socket);
//       socket.emit('waiting', 'Searching for a partner...');
//     }
//   });

//   socket.on('disconnect', () => {
//     waitingQueue = waitingQueue.filter(u => u.id !== socket.id);
//     console.log('User disconnected:', socket.id);
//   });
// });

// server.listen(3000, () => {
//   console.log('Backend running on http://localhost:3000');
// });


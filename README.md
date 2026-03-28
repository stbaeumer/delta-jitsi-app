# 💳 Delta Wallet

<img width="415" height="781" alt="pic1" src="https://github.com/user-attachments/assets/43f33826-a8a2-4f39-a808-6bedf11d0c97" />

<img width="415" height="781" alt="pic2" src="https://github.com/user-attachments/assets/e5b01080-37d5-440d-8ad7-90ca05bfc8e0" />

<img width="406" height="655" alt="pic3" src="https://github.com/user-attachments/assets/50c5592d-bf68-4cab-812b-3c6040609837" />


A simple and elegant wallet app for [Delta Chat](https://delta.chat/) to create and share digital wallet entries like tickets, coupons, membership cards, certificates, and more.

## 📋 What is Delta Wallet?

Delta Wallet allows you to easily create structured wallet entries with the following fields:

- **Title** - Name or designation of the wallet entry (e.g., "Cinema Ticket", "Coffee Membership Card")
- **Description** - Additional details about the entry
- **URL** - Link to more information or the digital ticket
- **QR Code** - Display a QR code image (optional)
- **Date & Time** - When the entry is relevant (e.g., expiration date, event time)

Each entry is beautifully formatted in a **wallet card** preview and can be sent directly to your Delta Chat contacts.

## 🎯 Features

✨ **Simple Form Interface** - Just fill in the fields you need  
📱 **Live Preview** - See exactly how your wallet card will look  
🌐 **Multi-language** - Currently available in German (de) and English (en)  
💬 **Delta Chat Integration** - Send wallet entries directly to your chat contacts  
🏷️ **Icons** - Each field is marked with a corresponding icon for quick recognition  
📦 **No Dependencies** - Runs entirely in your browser  

## 📱 For Delta Chat Users

This is a **WebXDC app** designed to work with [Delta Chat](https://delta.chat/). 

**How to use:**
1. Download the `.xdc` file from the [Releases](https://github.com/stbaeumer/delta-wallet/releases) page
2. Open Delta Chat and drag-and-drop the file into a chat
3. Fill in your wallet information
4. Click "Send" to share the formatted wallet card with your contacts

## 🚀 Releases & Versioning

Every commit automatically creates a **prerelease** on GitHub with an incremented patch version:
- `0.0.1` → `0.0.2` → `0.0.3` → etc.

You can always grab the latest version from the [Releases page](https://github.com/stbaeumer/delta-wallet/releases). Prerelease versions are automatically created and may include experimental features.

## 🔧 Technical Details

This app is written in [Fennel](https://fennel-lang.org/) - a Lisp dialect that compiles to Lua. It runs in the browser via [Fengari](https://github.com/fengari-lua/fengari), a JavaScript implementation of Lua.

### Architecture

- **Frontend**: Fennel → Lua → Fengari (JavaScript)
- **Styling**: [Pico CSS](https://picocss.com/) - a minimalist CSS framework
- **Icons**: [Solar Icon Set](https://icon-sets.iconify.design/solar/) (CC BY 4.0)
- **Rendering**: [RetroV](https://ratfactor.com/retrov/) - Virtual DOM library

### For Developers

#### Prerequisites

- [Lua 5.3](https://www.lua.org/)
- [Fennel](https://fennel-lang.org/) compiler
- [Lua FileSystem](https://lunarmodules.github.io/luafilesystem/)
- [Lua POSIX](https://github.com/luaposix/luaposix)
- [Zip](https://infozip.sourceforge.net/Zip.html)

**On Debian/Ubuntu:**
```bash
sudo apt install lua5.3 lua-filesystem lua-posix zip
```

Then install Fennel from https://fennel-lang.org/setup

#### Building

```bash
fennel build.fnl
```

This compiles the Fennel code to Lua, bundles everything, and creates:
- `index.html` - Standalone HTML file
- `dist/delta-wallet.xdc` - WebXDC app file for Delta Chat

## 📄 License

This is [open-source software](https://opensource.org/), released for free use.

### Base App Attribution

This project is based on the Found ICE app by durianbean:
- Project: https://durianbean.itch.io/found-ice

Many thanks to the original author for the idea and foundation.

### App Icon Attribution

The app icon file [icon.png](icon.png) is based on:
- "Softies-icons-wallet_256px.png" on Wikimedia Commons
- Source: https://commons.wikimedia.org/wiki/File:Softies-icons-wallet_256px.png

Please see the Wikimedia Commons page for the exact author and license details of that icon file.

### Contains bits and pieces of the following projects:

- [Fennel](https://fennel-lang.org/) - MIT License
- [Fengari](https://github.com/fengari-lua/fengari) - MIT License  
- [Pico CSS](https://picocss.com/) - MIT License
- [Solar Icon Set](https://icon-sets.iconify.design/solar/) - CC BY 4.0 License
- [RetroV](https://ratfactor.com/retrov/) - MIT License

Please support these projects if you can!

## 🤝 Contributing

Feel free to fork, modify, and improve this app. Pull requests are welcome!

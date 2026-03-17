# fserver

A minimal file upload server for receiving files from your phone over WiFi.

<img width="709" height="688" alt="image" src="https://github.com/user-attachments/assets/a5dcb764-4197-42bb-951f-7c5608b2a746" />

---

## Requirements

- Python 3.x
- Mac or Linux
- Both devices on the same WiFi network

---

## Install

```bash
chmod +x installer.sh && ./installer.sh
```

Restart your terminal, then:

```bash
fserver
```

---

## Usage

1. Run `fserver` in your terminal
2. You'll see something like:

```
  File Server running
  Local:   http://localhost:8080
  Mobile:  http://192.168.1.42:8080

  Saving files to: /Users/yourname/Downloads
```

3. Open the **Mobile** address in your phone's browser
4. Pick a file and hit Upload
5. File lands in your Downloads folder

---

## Stopping the server

`Ctrl + C`

---

## Notes

- Only works on the same WiFi network
- One file at a time
- Files go to `~/Downloads`
```




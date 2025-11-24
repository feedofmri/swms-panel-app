#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>
#include <WebSocketsServer.h>

const char* SSID = "Galaxy A53";
const char* PASS = "12345678";

const uint32_t ARDUINO_BAUD = 9600; // Serial baud
ESP8266WebServer http(80);          // http://<ip>/
WebSocketsServer ws(81);            // ws://<ip>:81/

String buf;

const char INDEX_HTML[] PROGMEM = R"HTML(
<!doctype html>
<html lang="bn">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>ESP8266 Serial Live</title>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Inter,Arial;
         margin:0;background:#0b1020;color:#e9eefb}
    header{padding:14px 16px;background:#111831;position:sticky;top:0}
    h1{font-size:16px;margin:0}
    main{padding:12px}
    #log{background:#0e1430;border:1px solid #1f2a4a;border-radius:10px;
         padding:12px;white-space:pre-wrap;font-family:ui-monospace,Consolas,monospace;
         height:60vh;overflow:auto}
    .row{display:flex;gap:8px;align-items:center;margin:10px 0}
    button{padding:8px 12px;border-radius:10px;border:1px solid #2a3a6b;background:#1a2454;color:#e9eefb;cursor:pointer}
    button:disabled{opacity:.6;cursor:not-allowed}
    .pill{padding:6px 10px;border-radius:999px;background:#16204a;border:1px solid #2a3a6b}
    a{color:#9ecbff}
  </style>
</head>
<body>
<header>
  <h1>ESP8266 Serial → WebSocket Viewer</h1>
</header>
<main>
  <div class="row">
    <span class="pill">WS: <span id="state">connecting…</span></span>
    <button id="clearBtn">Clear</button>
    <button id="pauseBtn">Pause</button>
    <label class="pill" style="display:flex;align-items:center;gap:6px;">
      <input id="autoscroll" type="checkbox" checked /> Autoscroll
    </label>
  </div>
  <div id="log"></div>
  <p>Tip: এই পেজের URL-এ IP ঠিকানাই আপনার WebSocket হোস্ট—আর কিছু লাগবে না।</p>
</main>
<script>
  const logEl = document.getElementById('log');
  const stateEl = document.getElementById('state');
  const pauseBtn = document.getElementById('pauseBtn');
  const clearBtn = document.getElementById('clearBtn');
  const autoscrollEl = document.getElementById('autoscroll');

  let paused = false;

  function appendLine(text){
    if(paused) return;
    const atBottom = logEl.scrollTop + logEl.clientHeight >= logEl.scrollHeight - 4;
    logEl.textContent += (text + "\\n");
    if(autoscrollEl.checked && atBottom){
      logEl.scrollTop = logEl.scrollHeight;
    }
  }

  clearBtn.onclick = () => { logEl.textContent = ""; };
  pauseBtn.onclick = () => {
    paused = !paused;
    pauseBtn.textContent = paused ? "Resume" : "Pause";
  };

  // Connect to ws://<host>:81/
  const url = ws://${location.hostname}:81/;
  const ws = new WebSocket(url);

  ws.onopen = () => { stateEl.textContent = "connected"; };
  ws.onclose = () => { stateEl.textContent = "closed"; };
  ws.onerror = () => { stateEl.textContent = "error"; };

  ws.onmessage = (ev) => {
    try {
      appendLine(ev.data);
    } catch (e) {
      appendLine(String(ev.data));
    }
  };
</script>
</body>
</html>
)HTML";

void onWs(uint8_t num, WStype_t type, uint8_t* payload, size_t len) {
  if (type == WStype_CONNECTED) {
    IPAddress ip = ws.remoteIP(num);
    Serial.printf("[WS] Client %u connected from %s\n", num, ip.toString().c_str());
  } else if (type == WStype_DISCONNECTED) {
    Serial.printf("[WS] Client %u disconnected\n", num);
  }
}

void handleRoot() {
  http.send_P(200, "text/html; charset=utf-8", INDEX_HTML);
}

void setup() {
  Serial.begin(ARDUINO_BAUD);
  delay(100);

  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASS);
  while (WiFi.status() != WL_CONNECTED) { delay(200); }

  http.on("/", handleRoot);
  http.onNotFound([](){ http.send(404, "text/plain", "Not found"); });
  http.begin();

  ws.begin();
  ws.onEvent(onWs);

  Serial.println();
  Serial.print("ESP Ready, IP: ");
  Serial.println(WiFi.localIP()); // উদাহরণ: 192.168.1.114
  Serial.println("Open: http://<IP>/  (e.g., http://192.168.1.114/)");
}

void loop() {
  ws.loop();
  http.handleClient();

  while (Serial.available()) {
    char c = (char)Serial.read();
    if (c == '\n') {
      buf.trim();
      if (buf.length()) {
        ws.broadcastTXT(buf);
      }
      buf = "";
    } else if (c != '\r') {
      if (buf.length() < 1024) {
        buf += c;
      } else {
        buf = "";
      }
    }
  }
}
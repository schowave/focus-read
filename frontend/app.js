const cameraInput = document.getElementById("camera-input");
const startScreen = document.getElementById("start-screen");
const loadingScreen = document.getElementById("loading-screen");
const readerScreen = document.getElementById("reader-screen");
const pageImage = document.getElementById("page-image");
const overlaysDiv = document.getElementById("overlays");
const wordDisplay = document.getElementById("word-display");
const btnBack = document.getElementById("btn-back");
const btnTts = document.getElementById("btn-tts");
const btnNext = document.getElementById("btn-next");
const btnNew = document.getElementById("btn-new");

let words = [];
let currentIndex = -1;
let imageWidth = 0;
let imageHeight = 0;
let ttsEnabled = true;

function showScreen(screen) {
  document.querySelectorAll(".screen").forEach((s) => s.classList.remove("active"));
  screen.classList.add("active");
}

// Camera capture
cameraInput.addEventListener("change", async (e) => {
  const file = e.target.files[0];
  if (!file) return;

  showScreen(loadingScreen);

  const form = new FormData();
  form.append("image", file);

  try {
    const res = await fetch("/api/ocr", { method: "POST", body: form });
    const data = await res.json();

    words = data.words;
    imageWidth = data.image_width;
    imageHeight = data.image_height;
    pageImage.src = data.image_url;

    pageImage.onload = () => {
      buildOverlays();
      currentIndex = -1;
      advance(1);
      showScreen(readerScreen);
    };
  } catch (err) {
    alert("Fehler bei der Texterkennung: " + err.message);
    showScreen(startScreen);
  }
});

function buildOverlays() {
  overlaysDiv.innerHTML = "";
  const displayW = pageImage.clientWidth;
  const displayH = pageImage.clientHeight;
  const scaleX = displayW / imageWidth;
  const scaleY = displayH / imageHeight;

  words.forEach((word, i) => {
    const el = document.createElement("div");
    el.className = "word-overlay dimmed";
    el.style.left = `${word.x * scaleX}px`;
    el.style.top = `${word.y * scaleY}px`;
    el.style.width = `${word.w * scaleX}px`;
    el.style.height = `${word.h * scaleY}px`;
    el.addEventListener("click", () => goToWord(i));
    overlaysDiv.appendChild(el);
  });
}

function goToWord(index) {
  if (index < 0 || index >= words.length) return;

  currentIndex = index;
  const overlayEls = overlaysDiv.children;

  for (let i = 0; i < overlayEls.length; i++) {
    overlayEls[i].className = i === index ? "word-overlay active" : "word-overlay dimmed";
  }

  wordDisplay.textContent = words[index].text;
  if (ttsEnabled) speak(words[index].text);
}

function advance(dir) {
  goToWord(currentIndex + dir);
}

// TTS
function speak(text) {
  speechSynthesis.cancel();
  const utter = new SpeechSynthesisUtterance(text);
  utter.lang = "de-DE";
  utter.rate = 0.8;
  speechSynthesis.speak(utter);
}

// TTS toggle
btnTts.addEventListener("click", () => {
  ttsEnabled = !ttsEnabled;
  btnTts.textContent = ttsEnabled ? "Vorlesen: An" : "Vorlesen: Aus";
  btnTts.classList.toggle("off", !ttsEnabled);
  if (!ttsEnabled) speechSynthesis.cancel();
});

// Controls
btnNext.addEventListener("click", () => advance(1));
btnBack.addEventListener("click", () => advance(-1));
btnNew.addEventListener("click", () => {
  cameraInput.value = "";
  wordDisplay.textContent = "";
  overlaysDiv.innerHTML = "";
  showScreen(startScreen);
});

// Keyboard navigation
document.addEventListener("keydown", (e) => {
  if (!readerScreen.classList.contains("active")) return;
  if (e.key === "ArrowRight" || e.key === " ") advance(1);
  if (e.key === "ArrowLeft") advance(-1);
});

// Rebuild overlays on resize
window.addEventListener("resize", () => {
  if (readerScreen.classList.contains("active")) buildOverlays();
});

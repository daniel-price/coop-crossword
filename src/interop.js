import { setupStickyCurrentClue } from "./setup-sticky-current-clue";
import { generateUsername } from "unique-username-generator";
import "./main.css";

export const flags = ({ env }) => {
  return {
    apiUrl: env.API_URL || "https://cooperative-crosswords-be.fly.dev/",
    teamId: getTeamId(),
    username: getUsername(),
    fontSize: getFontSize(),
    scrollableClues: getScrollableClues(),
  };
};

export const onReady = ({ app, env }) => {
  if (app.ports && app.ports.outgoing) {
    app.ports.outgoing.subscribe(({ tag, data }) => {
      switch (tag) {
        case "CREATE_WEBSOCKET":
          createWebSocket(app, env, data);
          return;

        case "SEND_WEBSOCKET_MESSAGE":
          sendWebSocketMessage(data);
          return;

        case "SETUP_FOCUS_INPUT_ON_CLICK":
          setupFocusInputOnClick();
          return;

        case "SHARE_LINK":
          shareLink(data);
          return;

        case "SAVE_FONT_SIZE":
          saveFontSize(data);
          return;

        case "SAVE_SCROLLABLE_CLUES":
          saveScrollableClues(data);
          return;

        default:
          console.warn(`Unhandled outgoing port: "${tag}"`);
          return;
      }
    });
  }
};

function toastInfo(text) {
  console.log("Showing info toast: ", text);
  toast(text, "info");
}

function toastSuccess(text) {
  console.log("Showing success toast: ", text);
  toast(text, "success");
}

function toastError(text, error = null) {
  let errorMessage = text;
  if (error instanceof Error) {
    errorMessage = `${text}: ${error.message}`;
  } else if (error) {
    errorMessage = `${text}: ${error}`;
  } else if (typeof error === "string") {
    errorMessage = `${text}: ${error}`;
  }
  console.error("Showing error toast: ", errorMessage, error);
  toast(errorMessage, "error");
}

function toast(text, type) {
  try {
    document.querySelectorAll(".toast").forEach((el) => {
      el?.remove();
    });
    const el = document.createElement("div");
    el.className = "toast";
    el.classList.add(`toast--${type}`);
    el.textContent = text;

    document.body.appendChild(el);

    setTimeout(() => {
      el?.remove();
    }, 2000);
  } catch (err) {
    console.error("Could not show toast: ", text, type);
  }
}

function copyToClipboard(text) {
  if (!navigator.clipboard) {
    toastError(
      "Could not copy link to clipboard",
      "Clipboard API not available",
    );
    return;
  }

  toastInfo("Copying link to clipboard...");

  navigator.clipboard
    .writeText(text)
    .then(() => {
      toastSuccess("Link copied to clipboard");
    })
    .catch((err) => {
      toastError("Could not copy link to clipboard", err);
    });
}

function shareLink(data) {
  const { url, title, text } = data;
  const shareData = {
    title: title || "Crossword Link",
    text: text || "Check out this crossword!",
    url: url,
  };

  if (navigator.share) {
    toastInfo("Sharing link...");
    navigator
      .share(shareData)
      .then(() => {
        toastSuccess("Link shared successfully");
      })
      .catch((err) => {
        if (err.name === "InvalidStateError") {
          // clicked twice very quickly, ignore
          return;
        }

        if (err.name === "AbortError") {
          toastInfo("Share canceled");
          return;
        }

        toastError("Could not share link", err);
      });
    return;
  }

  copyToClipboard(url);
}

function getTeamId() {
  const storedTeamId = localStorage.getItem("teamId");
  if (storedTeamId) {
    return storedTeamId;
  }
  const teamId = randomFourLetters();
  localStorage.setItem("teamId", teamId);
  return teamId;
}

function randomFourLetters() {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  let result = "";
  for (let i = 0; i < 4; i++) {
    result += alphabet.charAt(Math.floor(Math.random() * alphabet.length));
  }
  return result;
}

function getUsername() {
  const storedUsername = localStorage.getItem("username");
  if (storedUsername) {
    return storedUsername;
  }
  const username = generateUsername("-");
  localStorage.setItem("username", username);
  return username;
}

function getFontSize() {
  const storedFontSize = localStorage.getItem("fontSize");
  if (storedFontSize) {
    return storedFontSize;
  }
  return "Normal";
}

function saveFontSize(fontSize) {
  localStorage.setItem("fontSize", fontSize);
}

function getScrollableClues() {
  const stored = localStorage.getItem("scrollableClues");
  if (stored !== null) {
    return stored;
  }
  return "true";
}

function saveScrollableClues(value) {
  localStorage.setItem("scrollableClues", value);
}

let ws;

function createWebSocket(app, env, data) {
  const { WEBSOCKET_URL = "ws://cooperative-crosswords-be.fly.dev/" } = env;

  if (!WEBSOCKET_URL) {
    console.error("Websocket url is required to create websocket");
    return;
  }

  const createWebSocket = () => {
    const { crosswordId, teamId } = data;

    if (!crosswordId) {
      console.error("Crossword id is required to create websocket");
      return;
    }
    if (!teamId) {
      console.error("User id is required to create websocket");
      return;
    }

    const url = `${WEBSOCKET_URL}move/${teamId.toUpperCase()}/${crosswordId}/${getUsername()}`;
    ws = new WebSocket(url);

    ws.addEventListener("message", function (event) {
      app.ports.messageReceiver.send(event.data);
    });
    ws.onopen = function () {
      console.log(`Connected to websocket ${url}`);
    };
    ws.onclose = function () {
      console.log("Disconnected from websocket");
      createWebSocket();
    };
  };
  createWebSocket();
  console.log("Websocket created");
}

function sendWebSocketMessage(data) {
  if (!ws) {
    console.error("Websocket is not initialized");
    return;
  }

  ws.send(JSON.stringify(data));
}

/**
 * This function is called once, as soon as the crossword is loaded,
 * and enables us to have different behaviour for touch and non-touch devices.
 *
 * On touch devices, it is clear when the input is focussed as the on screen
 * keyboard is visible, but we don't always want it to be focussed as it takes
 * up screen space.
 * So, we only focus the input when a cell or clue is clicked, and let
 * the user click elsewhere to hide the keyboard.
 *
 * On non-touch devices, is it not clear if the input is focussed or not, but
 * we can just make sure that it is always focussed as it doesn't take up any
 * screen space.
 *
 * We set the onclick handlers rather than using Dom.focus() in Elm to prevent
 * a flicker of the onscreen keyboard, and also to avoid having to always
 * remember to fire a command to focus the input.
 */
async function setupFocusInputOnClick() {
  let i = 0;
  while (!document.querySelector(".crossword-input")) {
    i++;
    await new Promise((resolve) => setTimeout(resolve, 0));
    console.log("waiting for input to be available" + i);
  }
  const focusInput = () => {
    document.querySelector(".crossword-input")?.focus();
  };

  const setOnClickToFocusInput = (selector) => {
    const elements = document.querySelectorAll(selector);
    elements.forEach((el) => {
      el.onclick = focusInput;
    });
  };

  setupStickyCurrentClue();
  setupModalScrollDisable();

  const isTouchDevice = "ontouchstart" in document.documentElement;
  if (isTouchDevice) {
    setOnClickToFocusInput(".cell, .clue");
    return;
  }

  setOnClickToFocusInput("body");
  focusInput();
}

/**
 * Disables body scroll when modals are open.
 * Uses MutationObserver to watch for changes to modal-backdrop visibility.
 */
function setupModalScrollDisable() {
  const checkModalState = () => {
    const modals = document.querySelectorAll(".modal-backdrop");
    const hasVisibleModal = Array.from(modals).some(
      (modal) => !modal.classList.contains("modal-backdrop--hidden"),
    );

    if (hasVisibleModal) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
  };

  // Initial check (with a small delay to ensure modals might be rendered)
  setTimeout(checkModalState, 100);

  // Watch for changes to modal-backdrop elements
  const observer = new MutationObserver((mutations) => {
    // Only check if the mutation is related to modal elements
    const shouldCheck = mutations.some((mutation) => {
      const target = mutation.target;
      return (
        target.classList?.contains("modal-backdrop") ||
        target.classList?.contains("modal-backdrop--hidden") ||
        Array.from(mutation.addedNodes).some(
          (node) =>
            node.nodeType === 1 &&
            (node.classList?.contains("modal-backdrop") ||
              node.querySelector?.(".modal-backdrop")),
        )
      );
    });

    if (shouldCheck) {
      checkModalState();
    }
  });

  // Observe the document body for changes to modal elements
  observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["class"],
  });
}

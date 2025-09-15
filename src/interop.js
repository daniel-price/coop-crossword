import { iosSafariPositionSticky } from "./ios-safari-position-sticky";
import { generateUsername } from "unique-username-generator";

export const flags = ({ env }) => {
  return {
    apiUrl: env.API_URL || "https://cooperative-crosswords-be.fly.dev/",
    teamId: getTeamId(),
    username: getUsername(),
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

        case "COPY_TO_CLIPBOARD":
          copyToClipboard(data);
          return;

        default:
          console.warn(`Unhandled outgoing port: "${tag}"`);
          return;
      }
    });
  }
};

function copyToClipboard(text) {
  if (!navigator.clipboard) {
    console.error("Clipboard API not available");
    // Send failure feedback to Elm
    if (window.elmApp && window.elmApp.ports) {
      window.elmApp.ports.messageReceiver.send(false);
    }
    return;
  }
  navigator.clipboard
    .writeText(text)
    .then(() => {
      console.log("Text copied to clipboard");
      // Send success feedback to Elm
      if (window.elmApp && window.elmApp.ports) {
        window.elmApp.ports.messageReceiver.send(true);
        // Reset success state after 2 seconds
        setTimeout(() => {
          window.elmApp.ports.messageReceiver.send(false);
        }, 2000);
      }
    })
    .catch((err) => {
      console.error("Could not copy text: ", err);
      // Send failure feedback to Elm
      if (window.elmApp && window.elmApp.ports) {
        window.elmApp.ports.messageReceiver.send(false);
      }
    });
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

let ws;

function createWebSocket(app, env, data) {
  const { WEBSOCKET_URL } = env;

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
      console.log("Received message from websocket", event.data);
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
  while (!document.querySelector("#input")) {
    i++;
    await new Promise((resolve) => setTimeout(resolve, 0));
    console.log("waiting for input to be available" + i);
  }
  const focusInput = () => {
    document.querySelector("#input")?.focus();
  };

  const setOnClickToFocusInput = (selector) => {
    const elements = document.querySelectorAll(selector);
    elements.forEach((el) => {
      el.onclick = focusInput;
    });
  };

  const isTouchDevice = "ontouchstart" in document.documentElement;
  if (isTouchDevice) {
    setOnClickToFocusInput(".cell, .clue");
    iosSafariPositionSticky();
    return;
  }

  iosSafariPositionSticky();
  setOnClickToFocusInput("body");
  focusInput();
}

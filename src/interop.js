import { iosSafariPositionSticky } from "./ios-safari-position-sticky";

export const flags = ({ env }) => {
  return {
    apiUrl: env.API_URL,
    sessionId: window.crypto.randomUUID(),
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

        default:
          console.warn(`Unhandled outgoing port: "${tag}"`);
          return;
      }
    });
  }
};

let ws;

function createWebSocket(app, env, data) {
  const { WEBSOCKET_URL = "ws://127.0.0.1:8080/" } = env;

  if (!WEBSOCKET_URL) {
    console.error("Websocket url is required to create websocket");
    return;
  }

  const createWebSocket = () => {
    const { crosswordId, sessionId } = data;

    if (!crosswordId) {
      console.error("Crossword id is required to create websocket");
      return;
    }
    if (!sessionId) {
      console.error("User id is required to create websocket");
      return;
    }

    const teamId = 1; //TODO

    const url = `${WEBSOCKET_URL}move/${teamId}/${crosswordId}/${sessionId}`;
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
  while (!document.querySelector("#input")) {
    i++;
    await new Promise((resolve) => setTimeout(resolve, 0));
    console.log("waiting for input to be available" + i);
  }
  const focusInput = () => {
    document.querySelector("#input").focus();
  };

  const setOnClickToFocusInput = (selector) => {
    const elements = document.querySelectorAll(selector);
    elements.forEach((el) => {
      el.onclick = focusInput;
    });
  };

  const isTouchDevice = "ontouchstart" in document.documentElement;
  if (isTouchDevice) {
    /**
      *
#current-clue-wrap {
  position: sticky;
  top: 0px;
  width: 100%;
  z-index: 2;
}*/
    setOnClickToFocusInput(".cell, .clue");
    iosSafariPositionSticky();
    return;
  }

  iosSafariPositionSticky();
  setOnClickToFocusInput("body");
  focusInput();
}

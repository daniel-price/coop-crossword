const debounce = function (callback, delay) {
  let timer;
  return function () {
    clearTimeout(timer);
    timer = setTimeout(() => {
      callback();
    }, delay);
  };
};

const isElementOnScreen = function (element) {
  return element.getBoundingClientRect().bottom > -1;
};

/**
 * position:sticky doesn't work on iOS Safari as opening the virtual keyboard
 * moves the sticky element off the page. So this function is needed as
 * a workaround. See http://codemzy.com/blog/sticky-fixed-header-ios-keyboard-fix
 */
export const iosSafariPositionSticky = () => {
  const gridContainer = document.getElementById("grid");
  const currentClue = document.getElementById("current-clue");
  const input = document.getElementById("input");
  const header = document.getElementById("header");
  const headerSize = header.getBoundingClientRect().height;

  // function to set the margin to show the current clue if hidden
  const setMargin = function () {
    const shouldCreateAbsoluteCurrentClue =
      isElementOnScreen(gridContainer) && !isElementOnScreen(currentClue);

    if (!shouldCreateAbsoluteCurrentClue) {
      return;
    }

    const bodyTop = document.body.getBoundingClientRect().top;
    let currentClueDuplicate = document.getElementById(
      "current-clue-duplicate",
    );

    if (!currentClueDuplicate) {
      currentClueDuplicate = document
        .getElementById("current-clue")
        .cloneNode(true);
      document.getElementById("crossword-grid").append(currentClueDuplicate);

      currentClueDuplicate.id = "current-clue-duplicate";
    }

    currentClueDuplicate.style["position"] = "absolute";
    currentClueDuplicate.style["margin-top"] =
      Math.abs(bodyTop + headerSize) + "px";
  };

  const setMarginWithDebounce = debounce(setMargin, 250);

  const hideOrShowCurrentClue = function () {
    const currentClueDuplicate = document.getElementById(
      "current-clue-duplicate",
    );

    if (currentClueDuplicate) {
      currentClueDuplicate.remove();
    }

    setMarginWithDebounce();
  };

  window.addEventListener("scroll", hideOrShowCurrentClue);
  input.addEventListener("blur", hideOrShowCurrentClue); // when the virtual keyboard is dismissed
};

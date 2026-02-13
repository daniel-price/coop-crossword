/**
 * position:sticky doesn't work on iOS Safari as opening the virtual keyboard
 * moves the sticky element off the page. So this function is needed as
 * a workaround. See http://codemzy.com/blog/sticky-fixed-header-ios-keyboard-fix
 */
export const setupStickyCurrentClue = () => {
  const input = document.querySelector(".crossword-input");
  const gridContainerGrid = document.querySelector(".grid-container__grid");

  const updateCurrentClueDuplicate = function () {
    const currentClue = document.querySelector(".current-clue");
    const currentClueDuplicate = document.querySelector(
      ".current-clue-duplicate",
    );

    const currentClueTopIsOffScreen =
      currentClue.getBoundingClientRect().top < 0;

    if (currentClueTopIsOffScreen) {
      currentClueDuplicate.style.display = "block";
    } else {
      currentClueDuplicate.style.display = "none";
    }
  };

  window.addEventListener("scroll", updateCurrentClueDuplicate);
  input.addEventListener("blur", updateCurrentClueDuplicate); // when the virtual keyboard is dismissed
  //when the input is focused
  input.addEventListener("focus", updateCurrentClueDuplicate);
  window.addEventListener("click", updateCurrentClueDuplicate);
};

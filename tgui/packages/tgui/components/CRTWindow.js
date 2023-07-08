import { Window } from '../layouts';
export const CRTWindow = (props) => {
  return (
    <Window
      width={props.width}
      height={props.height}
      theme="space_80s"
      >
        <Window.Content scrollable={props.scrollable}>
          <div class="crt">
            <div class="scanline"></div>
            {props.children}
          </div>
        </Window.Content>
      </Window>
  );
}

/*
* @file
* @copyright 2023 Kmc2000, PowerfulBacon, Vivlas, Covertcorvid
* @license MIT
*/

import { Component, forwardRef } from 'inferno';
import { filter, map, sortBy } from 'common/collections';
import { flow } from 'common/fp';
import { useBackend, useLocalState } from '../backend';
import { Button, Section, Modal, Dropdown, Tabs, Box, Input, Flex, ProgressBar, Collapsible, Icon, Divider, Tooltip } from '../components';
import { Window, NtosWindow } from '../layouts';
import { clamp } from '../../common/math';

/**
 * Camera by @robashton returns Camera object.
 * Modified by @Kmc2000 for IE11
 *  constructor initial parameters:
 *  @param {context} str *required
 *  @param {settings} str *optional
  */
// <camera>
const Camera = {
  constructor: function (context, settings) {
    settings = settings || {};
    this.distance = settings.distance || 1000.0;
    this.lookAt = settings.initialPosition || [0, 0];
    this.context = context;
    this.fieldOfView = settings.fieldOfView || Math.PI / 4.0;
    this.viewport = {
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      width: 0,
      height: 0,
      scale: [settings.scaleX || 1.0, settings.scaleY || 1.0],
    };
    this.init();
  },

  /**
   * Camera Initialization
   * -Add listeners.
   * -Initial calculations.
   */
  init: function () {
    this.updateViewport();
  },

  /**
   * Applies to canvas context the parameters:
   *  -Scale
   *  -Translation
   */
  begin: function () {
    this.context.save();
    this.applyScale();
    this.applyTranslation();
  },

  /**
   * 2d Context restore() method
   */
  end: function () {
    this.context.restore();
  },

  /**
   * 2d Context scale(Camera.viewport.scale[0], Camera.viewport.scale[0]) method
   */
  applyScale: function () {
    this.context.scale(this.viewport.scale[0], this.viewport.scale[1]);
  },

  /**
   * 2d Context translate(-Camera.viewport.left, -Camera.viewport.top) method
   */
  applyTranslation: function () {
    this.context.translate(-this.viewport.left, -this.viewport.top);
  },

  /**
   * Camera.viewport data update
   */
  updateViewport: function () {
    this.aspectRatio = this.context.canvas.width / this.context.canvas.height;
    this.viewport.width = this.distance * Math.tan(this.fieldOfView);
    this.viewport.height = this.viewport.width / this.aspectRatio;
    this.viewport.left = this.lookAt[0] - (this.viewport.width / 2.0);
    this.viewport.top = this.lookAt[1] - (this.viewport.height / 2.0);
    this.viewport.right = this.viewport.left + this.viewport.width;
    this.viewport.bottom = this.viewport.top + this.viewport.height;
    this.viewport.scale[0] = this.context.canvas.width / this.viewport.width;
    this.viewport.scale[1] = this.context.canvas.height / this.viewport.height;
  },

  /**
   * Zooms to certain z distance
   * @param {*z distance} z
   */
  zoomTo: function (z) {
    this.distance = z;
    this.updateViewport();
  },

  /**
   * Moves the centre of the viewport to new x, y coords (updates Camera.lookAt)
   * @param {x axis coord} x
   * @param {y axis coord} y
   */
  moveTo: function (x, y) {
    this.lookAt[0] = x;
    this.lookAt[1] = y;
    this.updateViewport();
  },

  /**
   * Transform a coordinate pair from screen coordinates (relative to the canvas) into world coordinates (useful for intersection between mouse and entities)
   * Optional: obj can supply an object to be populated with the x/y (for object-reuse in garbage collection efficient code)
   * @param {x axis coord} x
   * @param {y axis coord} y
   * @param {obj can supply an object to be populated with the x/y} obj
   * @returns
   */
  screenToWorld: function (x, y, obj) {
    obj = obj || {};
    obj.x = (x / this.viewport.scale[0]) + this.viewport.left;
    obj.y = (y / this.viewport.scale[1]) + this.viewport.top;
    return obj;
  },

  /**
   * Transform a coordinate pair from world coordinates into screen coordinates (relative to the canvas) - useful for placing DOM elements over the scene.
   * Optional: obj can supply an object to be populated with the x/y (for object-reuse in garbage collection efficient code).
   * @param {x axis coord} x
   * @param {y axis coord} y
   * @param {obj can supply an object to be populated with the x/y} obj
   * @returns
   */
  worldToScreen: function (x, y, obj) {
    obj = obj || {};
    obj.x = (x - this.viewport.left) * (this.viewport.scale[0]);
    obj.y = (y - this.viewport.top) * (this.viewport.scale[1]);
    return obj;
  },
};// </camera>

/*
 * Original author: nhz-io
 * License: MIT
 * Source (14/05/2023): https://github.com/nhz-io/inferno-canvas-component
 */
class InfernoCanvasComponent extends Component {
  static defaultProps = {
    draw() {}, // eslint-disable-line no-empty-function
    realtime: false,
    top: 0,
    left: 0,
  }

  getChildContext() {
    const { context, props, canvasElement } = this;
    const ctx = (context && context.ctx) || (canvasElement && canvasElement.getContext('2d'));
    const realtime = (context && context.realtime) || props.realtime;

    return { ctx, realtime };
  }

  constructor(props) {
    super(props);
    this.refDOM = this.refDOM.bind(this);
    this.requestAnimationFrameCallback = this.requestAnimationFrameCallback.bind(this);
  }

  componentDidMount() {
    this.forceUpdate();
    requestAnimationFrame(this.requestAnimationFrameCallback);
  }

  render() {
    const { props, context } = this;
    const { draw, realtime, top, left, ...other } = props; // eslint-disable-line no-unused-vars
    requestAnimationFrame(this.requestAnimationFrameCallback);

    if (context.ctx) {
      return <div key="canvas" {...other}>{props.children}</div>;
    }

    // WARNING: The tabindex bit MIGHT lag it out! but is required to focus the canvas.
    return <canvas tabindex="1" class="bg-space" ref={this.refDOM} key="canvas" {...other}>{props.children}</canvas>;
  }

  refDOM(element) {
    this.canvasElement = element;
  }

  requestAnimationFrameCallback(time) {
    if (this.previousFrameTime !== time) {
      const { props, context, canvasElement } = this;
      const { draw, top, left } = props;
      const ctx = (context && context.ctx) || (canvasElement && canvasElement.getContext('2d'));
      const realtime = (context && context.realtime) || props.realtime;

      let delta = 0;

      if (!draw || !ctx) {
        return;
      }


      if (realtime) {
        requestAnimationFrame(this.requestAnimationFrameCallback);

        if (this.previousFrameTime) {
          delta = time - this.previousFrameTime;
        }
        else {
          this.previousFrameTime = time;
        }

        this.previousFrameTime = time;
      }

      if (top || left) {
        ctx.translate(left, top);
      }

      draw({ time, delta, ctx });

      if (top || left) {
        ctx.translate(-1 * left, -1 * top); // eslint-disable-line no-magic-numbers
      }
    }
  }
}

const canvasWidth = 800;
const canvasHeight = 600;
// Frontend "prediction" constants (old):

/*
//The backend processes at a delay of Xms.
const backend_wait_time = 100; //WAS: 200
//We get a position update every (ROUGHLY) Xms:
const backend_update_interval = 100;//900;
//Which means we wait (usually) 30ms between our updates on screen.
const tick_rate = (backend_update_interval / backend_wait_time) * 10;
const delta_tr = (backend_wait_time / tick_rate);
*/
// The backend runs at this delay.
const backend_tick_rate = 100;
// Which gives us this many FPS if we don't do any interpolation.
const backend_fps = 1000/backend_tick_rate;
// We want to interpolate UP to this framerate. The client MUST be capable of running at least this fast.
const max_ideal_fps = 60;
let target_fps = max_ideal_fps;// 30;
// Which means we have this many ticks per actual game tick
let interpolation_mult = target_fps/backend_fps;
// Giving us a tick rate as such. This is the delay for framerate we have to use.

let tick_rate = backend_tick_rate / interpolation_mult;

class overmapEntity {
  constructor(x, y, z, angle, velocity, velocity_x, velocity_y, icon, thruster_power, rotation_power, sensor_range, armour_quadrants, inertial_dampeners, thermal_signature) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.angle = angle;
    this.velocity = velocity;
    this.velocity_x = velocity_x;
    this.velocity_y = velocity_y;
    this.icon = icon;
    this.thruster_power = thruster_power / interpolation_mult;
    this.rotation_power = rotation_power / interpolation_mult;
    this.sensor_range = sensor_range;
    // Pre-calculate radians.
    this.r = (this.angle) * (Math.PI / 180);
    this.armour_quadrants = armour_quadrants;
    this.inertial_dampeners = inertial_dampeners;
    this.thermal_signature = thermal_signature;
  }
  // The following procs are mirrored from the backend.
  // They attempt to model where the ship "ought" to be, based on input.
  process() {
    // TODO: this calculation is off
    this.x += (this.velocity_x/interpolation_mult);
    this.y += (this.velocity_y/interpolation_mult);
    /*

    if(this.inertial_dampeners){
      let fx = Math.cos(this.r);
      let fy = Math.sin(this.r); //This appears to be a vector.
      let sx = fy;
      let sy = -fx;
      let side_movement = (sx*this.velocity_x) + (sy*this.velocity_y);
      let friction_impulse = (this.thruster_power); //Weighty ships generate more space friction
      let clamped_side_movement = clamp(side_movement, -friction_impulse, friction_impulse);
      this.velocity_x -= clamped_side_movement * sx;
      this.velocity_y -= clamped_side_movement * sy;
    }
    */


  }
  rotate(dir) {
    // TODO: bodge
    this.angle += this.rotation_power * dir;
    this.r = (this.angle) * (Math.PI / 180);
  }
  thrust(dir) {
    // TODO: bodge
    // this.velocity += this.thruster_power * dir;
    switch (dir) {
      case (8):
        this.velocity_y -= this.thruster_power;
        break;
      case (2):
        this.velocity_y += this.thruster_power;
        break;
      case (4):
        this.velocity_x -= this.thruster_power;
        break;
      case (6):
        this.velocity_x += this.thruster_power;
        break;
      default:
        if (dir == 1) {
          this.velocity_x += Math.cos(this.r) * this.thruster_power;
          this.velocity_y += Math.sin(this.r) * this.thruster_power;
        }
        else {
          this.velocity_x *= 0.5;
          this.velocity_y *= 0.5;
          if (this.velocity_x < 0) {
            this.velocity_x = 0;
          }
          if (this.velocity_y < 0) {
            this.velocity_y = 0;
          }
          /*
          this.velocity_x -= Math.cos(this.r) * this.thruster_power;
          this.velocity_y -= Math.sin(this.r) * this.thruster_power;
          if (this.velocity < 0)
          { this.velocity = 0; }
          */
        }
        break;
    }
  }
}


export const JSOvermapGame = (props, context) => {
  const { act, data } = useBackend(context);
  let world = [];
  let keys = data.keys;
  let active_ship = null;
  const can_pilot = data.can_pilot;

  const rows = 26;
  const cols = 26;
  const abs=Math.abs;
  let icon_cache = data.icon_cache;
  const gridsize = 2000;
  let previous_frame_time = -1;
  if (data.fps_capability != -1) {
    target_fps = data.fps_capability;
    interpolation_mult = target_fps/backend_fps;
    tick_rate = backend_tick_rate / interpolation_mult;
  }
  // TODO: maybe try an update flag which triggers a repaint or not?
  if (data != null && data.physics_world.length > 0) {
    // world = data.physics_world;
    world = [];

    for (let I = 0; I < data.physics_world.length; I++) {
      let ship = data.physics_world[I];
      // log(`Sprite: ${icon_cache[ship.type]}`);
      const sprite = new Image();
      // sprite.src = `data:image/jpeg;base64,${icon_cache[ship.type]}`;
      sprite.src = icon_cache[ship.type];
      world[I] = new overmapEntity(ship.position[0], ship.position[1], ship.position[2], ship.position[3], ship.position[4], ship.position[5], ship.position[6], sprite, ship.thruster_power, ship.rotation_power, ship.sensor_range, ship.armour_quadrants, ship.inertial_dampeners, ship.thermal_signature);
      if (ship.active) {
        active_ship = world[I];
      }
    }
    let ctx = null;
    function HandleKeyUp(e) {
      if (keys[""+e.keyCode]) {
        act('keyup', { key: e.keyCode });
      }
      // Report to client to set zoom accordingly.
      if (e.keyCode == 81 || e.keyCode == 69) {
        act('set_zoom', { key: Camera.distance });
      }
      keys[""+e.keyCode] = false;
      e.preventDefault();
    }
    function HandleScroll(e) {
      act('scroll', { key: e.deltaY });
    }
    function HandleKeyDown(e) {
      if (!keys[""+e.keyCode]) {
        act('keydown', { key: e.keyCode });
      }
      keys[""+e.keyCode] = true;
      e.preventDefault();
    }
    function log(str) {
      act('log', { text: str });
    }
    let next_zoom_report = 0;
    function process_input(time) {
      let zoomLevel = 0;

      // Arrow keys handle strafing...
      if (keys["38"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.thrust(8);
      }

      if (keys["40"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.thrust(2);
      }

      if (keys["39"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.thrust(6);
      }

      if (keys["37"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.thrust(4);
      }

      // A&D
      if (keys["68"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.rotate(1);
      }
      if (keys["65"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.rotate(-1);
      }
      // W&S
      if (keys["87"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.thrust(1);
      }

      if (keys["18"]) {
        if (!can_pilot || active_ship == null)
        { return; }
        active_ship.thrust(-1);
      }
      // Handle zoom first.
      // Q to zoom out
      if (keys["81"]) {
        zoomLevel = Camera.distance + (1 * 100);
        if (zoomLevel <= 100) {
          zoomLevel = 100;
        }
        Camera.zoomTo(zoomLevel);
        // Report our zoom to the backend.
        if (time >= next_zoom_report) {
          next_zoom_report = time + 50;
          act('set_zoom', { key: Camera.distance });
        }
        // act('scroll', { key: 1 });
      }
      // E to zoom in
      if (keys["69"]) {
        zoomLevel = Camera.distance + (-1 * 100);
        if (zoomLevel <= 100) {
          zoomLevel = 100;
        }
        Camera.zoomTo(zoomLevel);
        // Report our zoom to the backend.
        if (time >= next_zoom_report) {
          next_zoom_report = time + 50;
          act('set_zoom', { key: Camera.distance });
        }
        // act('scroll', { key: -1 });
      }

      if (keys["32"]) {
        // TODO: fill out the weapon to be whatever active weapon we have. I don't care right now for the demo :)
        // Also todo: mouse aiming!
        act('fire', { weapon: -1, coords: { x: -1, y: -1, angle: -1 } });
      }

    }


    /**
   * Get an angle, in degrees, between two points.
   * Degrees are what BYOND likes!
   * @param {*} x1
   * @param {*} y1
   * @param {*} x2
   * @param {*} y2
   * @returns
   */
    function get_angle(x1, y1, x2, y2) {
      return Math.atan2((y2 - y1), (x2 - x1)) * 180 / Math.PI + 90; // Quadrant 0-90 should be northeast.
    }

    let canvas_rect = null;
    function HandleMouseDown(e) {
      if (canvas_rect == null || active_ship == null) {
        return;
      }
      let xy = Camera.screenToWorld(e.clientX - canvas_rect.left, Camera.screenToWorld(e.clientY - canvas_rect.top));

      act('fire', { weapon: -1, coords: { x: xy.x, y: xy.y, angle: get_angle(xy.x, xy.y, active_ship.x, active_ship.y) } });
    }

    let last_process_time = 0;
    // How long we've been slipping UNDER our target FPS for.
    let fps_lag_stacks = 0;
    // How long we've been throttled for, IE, we can do more than what we're throttled to.
    let fps_good_stacks = 0;
    // Did we request a UI update? Terminates all rendering.
    let mark_dirty_requested = false;
    // The maximum number of frames we'll accept being slow for. Defaults to 1 second's worth.
    // (higher -> more lag accepted before we try compensate.)
    const max_acceptable_frame_drift = max_ideal_fps;
    // How many consecutive frames we have been held back for. (higher -> longer time to jump back to 60fps.)
    const min_acceptable_frame_recovery_drift = 5;// max_acceptable_frame_drift / 2;

    const sensor_mode = data.sensor_mode;

    let last_input_process = 0;
    // Called every tick that the browser can handle.
    function _render({ time, delta, ctx }) {
      if (mark_dirty_requested) {
        return;
      }
      const actual_rate = time - last_process_time;
      let process = (actual_rate >= tick_rate);
      // Initial draw batch.
      if (last_process_time == 0) {
        Camera.constructor(ctx);
        if (active_ship != null) {
          Camera.moveTo(active_ship.x, active_ship.y);
        }
        Camera.zoomTo(data.client_zoom);
        canvas_rect = ctx.canvas.getBoundingClientRect();
      }
      // If we're now able to render at the correct framerate after being compensated down...
      // We report back and request the maximum possible FPS.
      if (target_fps != max_ideal_fps) {
        // We are being throttled, but are capable of more. Increase the good boy counter.
        if (!process) {
          fps_good_stacks++;
        }
        else {
          // Nope, can't handle it...
          fps_good_stacks--;
          if (fps_good_stacks < 0) {
            fps_good_stacks = 0;
          }
        }
        // You must have been continuing to render at above your real framerate for at least a few seconds worth of "ideal" fps time.
        if (fps_good_stacks >= min_acceptable_frame_recovery_drift) {
          // Abort all processing and get us an update, pronto.
          mark_dirty_requested = true;
          act('ui_mark_dirty', { fps: max_ideal_fps });
          return;
        }
      }

      // Slave clientside update to ROUGHLY server speed.
      if (!process) {
        return;
      }
      // We are hitting a major lag spike. We may need to intervene.
      // Should never exceed the target framerate as we are throttled to that speed.
      const rate_drift = actual_rate - tick_rate;
      // If we are more than 10 ms out of sync with the "ideal" rate.
      if (rate_drift >= 10) {
        // Increase our lag stacks.
        fps_lag_stacks++;
        // And, if we are lagging too hard to even be playable...
        if (fps_lag_stacks >= max_acceptable_frame_drift) {
          // Abort everything, report back what FPS we think we're capable of.
          const actual_fps = 1000 / actual_rate;
          mark_dirty_requested = true;
          // And get a UI update :)
          act('ui_mark_dirty', { fps: actual_fps });
          return;
        }
      }
      else {
        fps_lag_stacks = 0;
      }
      last_process_time = time;
      function draw(image, x, y, degrees) {
        let w = image.width;
        let h = image.height;
        degrees = degrees * Math.PI / 180;
        ctx.translate(x + w / 2, y + h / 2);

        ctx.rotate(degrees);

        ctx.drawImage(image, 0, 0, w, h,
          -w / 2, -h / 2, w, h);

        ctx.rotate(-degrees);
        ctx.translate(-x - w / 2, -y - h / 2);
      }

      // TODO: does not work
      function renderFiringArc(image, x, y, angle, start, end, colour="green", radius=300) {
        let w = image.width;
        let h = image.height;
        ctx.strokeStyle = colour;
        ctx.save();
        ctx.translate(x + w / 2, y + h / 2);

        ctx.rotate(angle+start);
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(-radius, 0);
        ctx.rotate(angle+end);
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(-radius, 0);

        ctx.translate(-x - w / 2, -y - h / 2);
        ctx.restore();
        ctx.stroke();


      }
      function radians(d) {
        return d * Math.PI / 180;
      }


      // Mirrored from BYOND side. These constants dictate armour thickness values for rendering.
      const OVERMAP_ARMOUR_THICKNESS_NONE = 0;
      const OVERMAP_ARMOUR_THICKNESS_LIGHT = 250;
      const OVERMAP_ARMOUR_THICKNESS_MEDIUM = 500;
      const OVERMAP_ARMOUR_THICKNESS_HEAVY = 1000;
      const OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY = 1500;
      const OVERMAP_ARMOUR_THICKNESS_ABLATIVE = 2000;
      const OVERMAP_ARMOUR_THICKNESS_GIGA = 2500;

      function drawArmourQuadrants(image, x, y, radius, offset, segments, size) {
        let w = image.width;
        let h = image.height;

        dashedCircle(x + w / 2, y + h / 2, w, offset, segments, size);

      }

      /**
         * ctx - context
         * x / y = center
         * radius = of circle
         * offset = rotation in angle (radians)
         * How many segments circle should be in
         * Size of each segment (of one segment) [0.0, 1.0]
         *
         * CC-Attr: Ken Fyrstenberg
         * Modified by: Kmc2000
        */
      function dashedCircle(x, y, radius, offset, segments, size) {

        let pi2 = 2 * Math.PI; // Total radians in a circle
        let sector_width_radians = pi2 / segments.length;
        let arc_length_radians = sector_width_radians * size;
        let arc_start_radians = (1 - size) * sector_width_radians / 2; // Offset start to half the width of the space between segments
        let ax, ay;

        let segment_count = 0;
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(offset);
        ctx.translate(-x, -y);
        for (; arc_start_radians < pi2; arc_start_radians += sector_width_radians) {
          ctx.beginPath();
          ax = x + radius * Math.cos(arc_start_radians);
          ay = y + radius * Math.sin(arc_start_radians);
          ctx.moveTo(ax, ay);
          let quad = segments[segment_count];
          let max_integrity = quad[1];
          ctx.lineWidth = 1;
          if (max_integrity >= OVERMAP_ARMOUR_THICKNESS_LIGHT) {
            ctx.lineWidth = 2.5;
          }
          if (max_integrity >= OVERMAP_ARMOUR_THICKNESS_MEDIUM) {
            ctx.lineWidth = 5;
          }
          if (max_integrity >= OVERMAP_ARMOUR_THICKNESS_HEAVY) {
            ctx.lineWidth = 10;
          }
          if (max_integrity >= OVERMAP_ARMOUR_THICKNESS_SUPER_HEAVY) {
            ctx.lineWidth = 15;
          }
          if (max_integrity >= OVERMAP_ARMOUR_THICKNESS_ABLATIVE) {
            ctx.lineWidth = 20;
          }
          if (max_integrity >= OVERMAP_ARMOUR_THICKNESS_GIGA) {
            ctx.lineWidth = 40;
          }

          let integrity = quad[0] / max_integrity * 100;

          if (integrity <= 0) {
            ctx.strokeStyle = "rgba(0,0,0,0)";
          }
          else if (integrity < 30) {
            ctx.strokeStyle = "red";
          }
          if (integrity >= 30) {
            ctx.strokeStyle = "orange";
          }
          if (integrity >= 50) {
            ctx.strokeStyle = "gold";
          }
          if (integrity >= 70) {
            ctx.strokeStyle = "dodgerblue";
          }
          segment_count++;
          ctx.arc(x, y, radius, arc_start_radians, arc_start_radians + arc_length_radians);
          ctx.stroke();
        }
        ctx.restore();
      }

      // TODO: set ctx in SetState? Then avoid redraws...
      // TODO: is this thing ACTUALLY re-rendering? I don't think it is!
      function drawCircle(image, x, y, radius) {
        ctx.strokeStyle = "green";
        let w = image.width;
        let h = image.height;
        ctx.beginPath();
        // ctx.arc((this.position.x - camera.x()) + w/2, (this.position.y-camera.y())+h/2, radius/scale, 0, 2 * Math.PI);
        ctx.arc((x) + w/2, (y)+h/2, radius, 0, 2 * Math.PI);

        ctx.stroke();
      }

      /**
       * Author(s): DeltaFire, Kmc2000
       * Interference Tracking System core code, aka the wobbly circle.
       * Draws the sensor circle around the ship, based on a scan mode.
       * For now, mostly visual and a slightly overpowered radar.
       * Wobbly circle spikes in the direction of a signature based on its size.
       *
       * IR mode:
       * - Signature is based on heat signature.
       * - If the object is a star.. expect huge signature.
       * - TODO: if they fire weapons, should spike the sensors!
       *
       * This will eventually be down to the science officer (radar operator) to select scan mode!
       * @param {*} image
       * @param {*} x
       * @param {*} y
       * @param {*} radius
       */
      function drawSensorCircle(image, x, y) {
        switch (sensor_mode) {
          // IR sensors...
          case (0):
            ctx.strokeStyle = "orange";
            break;
        }
        let w = image.width;
        let h = image.height;
        let radius = w*2;
        let circle_core_x = (x) + w/2;
        let circle_core_y = (y)+h/2;


        // Note / TODO: Many of these variables could / should be influenced or set by a) scan mode, b) sensor tech and c) condition of the ship's sensors.

        // "Wobbly" interference-related vars.
        let inter_impact = 30; // This is the total amount of vectorshifting our interference does. Amplified by some random factors.
        let inter_resolution = 31; // How high does the random number potentially go
        let inter_cut = 0.01; // The random number gets divided by this
        // inter_resolution * inter_cut = what inter_impact is multiplied with, reads, its intensity.

        // Signature angle-propagation vars.
        let signature_cutoff = 10; // Anything that ends up below this after a angle propagation is omitted. If base signal, still used.
        let max_angular_spread = 15; // 10? // Signatures can only spread at most this angle into each direction
        let signature_propagation_multiplier = 0.8; // 0.5? // Signatures have their value multiplied by this when propagating angles. Diminishing returns.

        // Anything after this point is not random vars you can play with - you have been warned.
        const point_count = 360; // If you change this, this stops working.. honestly 360 is a very nice var for less-math's sake, and it seems high-enough res.
        let datapoints = new Array(point_count); // interference datapoints - could probably just be local var, but keeping it for the moment - TODO - revisit.
        for (let i=0; i<point_count; i++)
        {
          // Interference signature...
          datapoints[i] = 0 + (Math.floor((Math.random() * inter_resolution)) * inter_cut); // 0.0 - 3.0 as scaling for impact
        }
        let signature_list = new Array(point_count); for (let i=0; i<point_count; i++) signature_list[i] = 0; // Collection of each total signature value by datapoint
        let strongest_signature = new Array(point_count); for (let i=0; i<point_count; i++) strongest_signature[i] = 0; // The strongest signature per datapoint
        // Now, scan for nearby ships large enough to produce a heat signature.
        for (let j = 0; j < world.length; j++) {
          let ship = world[j];
          if (ship == active_ship) {
            continue;
          }
          let ship_sig = ship.thermal_signature;
          if (ship_sig <= 0) {
            continue;
          }
          let angle = Math.floor((360 + get_angle(circle_core_x, circle_core_y, ship.x, ship.y))) % 360; // There will be no negative angles in this household.

          signature_list[angle] += ship_sig; // TODO: add potential for decrease by distance to target - none, linear, inverse_square, etc.
          if (strongest_signature[angle] < ship_sig) {
            strongest_signature[angle] = ship_sig;
          }
          for (let angle_iter = 1; angle_iter <= max_angular_spread; angle_iter++) { // We ball
            ship_sig *= signature_propagation_multiplier; // signature loss per angle point - TODO: check other potential curve styles for looks.
            if (ship_sig < signature_cutoff) {
              break;
            }
            let handled_angle_ccw = (360 + angle - angle_iter) % 360;
            let handled_angle_cw = (360 + angle + angle_iter) % 360;

            // Same TODO as above list add - need to consider distance reduction, or at least codewise support for it.
            signature_list[handled_angle_ccw] += ship_sig;
            if (strongest_signature[handled_angle_ccw] < ship_sig) {
              strongest_signature[handled_angle_ccw] = ship_sig;
            }
            signature_list[handled_angle_cw] += ship_sig;
            if (strongest_signature[handled_angle_cw] < ship_sig) {
              strongest_signature[handled_angle_cw] = ship_sig;
            }
          }
        }
        let start_signature_impact = 0;
        if (strongest_signature[0] > 0) {
          let start_secondary_signatures = (signature_list[0] - strongest_signature[0]) * Math.min((signature_list[0] - strongest_signature[0]) / strongest_signature[0], 1);
          start_signature_impact = strongest_signature[0] + Math.min(start_secondary_signatures, strongest_signature[0] * 0.2);
        }
        let start_vector = radius + (inter_impact * datapoints[0]) + start_signature_impact;
        ctx.beginPath();
        ctx.moveTo(circle_core_x, circle_core_y - start_vector);
        for (let i=1; i<point_count; i++)
        {
          let angulis = (i) % 360; // I am too tired for angular math so deal with it.
          let total_offset = inter_impact * datapoints[i];
          let signature_impact = 0;
          if (strongest_signature[i] > 0) { // This sure is some of the math of all time.
            let secondary_signatures = (signature_list[i] - strongest_signature[i]) * Math.min((signature_list[i] - strongest_signature[i]) / strongest_signature[i], 1);
            signature_impact = strongest_signature[i] + Math.min(secondary_signatures, strongest_signature[i] * 0.2);
          }

          let x_offset = (radius + total_offset + signature_impact) * Math.sin(angulis * Math.PI / 180);
          let y_offset = -(radius + total_offset + signature_impact) * Math.cos(angulis * Math.PI / 180);

          ctx.lineTo(circle_core_x + x_offset, circle_core_y + y_offset);
        }
        ctx.lineTo(circle_core_x, circle_core_y - start_vector);
        ctx.stroke();
      }

      ctx.clearRect(0, 0, 1280, 720);
      // ctx.fillStyle = "transparent";
      // ctx.fillRect(0, 0, canvas.width, canvas.height);


      if (Camera.distance >= 3000) {
        ctx.beginPath();
        // Todo: remove these?
        ctx.fillStyle = "rgba(0,0,0,0.25)";
        ctx.fillRect(0, 0, 1280, 720);
        // todo: world height instead of canvas height...
        for (let i = 0; i < rows; i++) {
          for (let j = 0; j < cols; j++) {
            const obj = Camera.worldToScreen(gridsize*i, gridsize*j);
            ctx.strokeStyle = "rgba(0,255,0,0.2)";
            ctx.fillStyle = "rgba(0,0,0,0.25)";
            ctx.moveTo(obj.x, 0);
            ctx.lineTo(obj.x, 720);
            ctx.moveTo(0, obj.y);
            ctx.lineTo(1280, obj.y);
            ctx.fillStyle = "green";
            ctx.font = "12pt consolas";
            ctx.fillText(String.fromCharCode(65+i)+j, obj.x, obj.y);
          }
        }
        ctx.stroke();
      }
      ctx.strokeStyle = "green";
      Camera.begin();
      process_input(time);
      // TODO: maybe needs map, here?
      // Didn't break when just displaying static sprites.
      for (let I = 0; I < world.length; I++) {
        let ship = world[I];
        // TODO: Is visible checks... we can use frustrum culling
        let x = ship.x;
        let y = ship.y;
        if (ship.icon != "" && x <= Camera.viewport.width+Camera.viewport.left && y <= Camera.viewport.height+Camera.viewport.top) {
          try {
            draw(ship.icon, ship.x, ship.y, ship.angle + 90);
          }
          catch (e) {
            continue;
          }

          if (ship.armour_quadrants.length > 0) {
            drawArmourQuadrants(ship.icon, ship.x, ship.y, 180, radians(ship.angle + 90), ship.armour_quadrants, 0.8);
          }
          if (ship.sensor_range > 0) {
            drawCircle(ship.icon, ship.x, ship.y, ship.sensor_range);
            // TODO: firing arcs! You get one for now :)

            // renderFiringArc(ship.icon, ship.x, ship.y, ship.angle-90, 315, 40);

          }
        }
        ship.process();

      }
      if (active_ship != null) {
        Camera.moveTo(active_ship.x, active_ship.y);
      }
      drawSensorCircle(active_ship.icon, active_ship.x, active_ship.y);
      Camera.end();
      // requestAnimationFrame(_render);
    }
    return (
      <InfernoCanvasComponent
        onKeyDown={(e) => {
          HandleKeyDown(e);
        }}
        onKeyUp={(e) => {
          HandleKeyUp(e);
        }}
        onMouseDown={(e) => {
          HandleMouseDown(e);
        }}
        draw={_render} realtime width={1280} height={720} />
    ); }
};
export const JSOvermap = (props, context) => {
  return (
    <Window
      width={1280}
      height={720}>
      <Window.Content>
        <JSOvermapGame props={props} context={context} />
      </Window.Content>
    </Window>
  ); };

# PS1 Horror Project Foundation

## Project Structure
- `_core/`: Global managers (EventBus, AudioManager, NetworkManager).
- `entities/`: Player, Enemy, Interactive objects (Door).
- `components/`: Reusable logic (Interaction, Health, etc.).
- `scenes/`: Game worlds and test maps.
- `ui/`: User Interface and Shaders.

## How to Run

1. **Open the Project** in Godot 4.3+.
2. **Run the Game**:
   - Press **F5** (or Play button) to start the `TestCorridor` scene.
3. **Multiplayer Test**:
   - Go to `Debug` -> `Run Multiple Instances` -> `Run 2 Instances`.
   - In one window, click **Host Game**.
   - In the second window, click **Join Game**.
   - You should see two players synchronized.

## Controls
- **WASD**: Move
- **Shift**: Sprint
- **Space**: Jump
- **Mouse**: Look
- **E**: Interact

## Features Implemented
- **PS1 Aesthetics**: 
  - Low resolution (320x240 viewport).
  - Vertex Jitter shader on meshes.
  - Dithering and Color Depth reduction post-process.
- **FSM (Finite State Machine)**:
  - Player states: Idle, Walk, Run, Interact.
  - Enemy states: Patrol, Chase, Attack.
- **Networking**:
  - Basic Host/Join system.
  - Position synchronization.
  - State synchronization.

## Documentation
- [Procedural Animator Guide](docs/procedural_animator_guide.md) - How to use the procedural animation system for characters without pre-made animations.

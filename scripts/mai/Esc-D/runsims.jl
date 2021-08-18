# Escenario D: Evaluación de criterios básicos con método de remuestreo por bloques 
using DrWatson 
@quickactivate "HEMI"

# Utilizar esta configuración para obtener status de las simulaciones, ya que
# las del método de subyacente MAI son particularmente lentas. Telegram,
# LoggingExtras y ConfigEnv deben estar instalados en el entorno global. No se
# ha decidido aún si incluirlos en el entorno principal 
using Telegram
using Logging, LoggingExtras
using ConfigEnv

# El archivo .env debe contener las llaves TELEGRAM_BOT_TOKEN y TELEGRAM_BOT_CHAT_ID
dotenv(projectdir()) 

# Configurar logger en Telegram 
tg = TelegramClient()
tg_logger = TelegramLogger(tg; async = false)
demux_logger = TeeLogger(
    MinLevelLogger(tg_logger, Logging.Info),
    ConsoleLogger()
)
global_logger(demux_logger)

## 
# Variantes MAI F, G y FP con [3, 4, 5, 8, 10, 20, 40] segmentos 
include("D19-36/eval-CoreMai.jl")
include("D19-60/eval-CoreMai.jl")
include("D20-36/eval-CoreMai.jl")
include("D20-60/eval-CoreMai.jl")

## Optimización de cuantiles con datos hasta 2019 
include("D19-36/optim-CoreMai.jl")
include("D19-60/optim-CoreMai.jl")

## Optimización de cuantiles con datos hasta 2020
include("D20-36/optim-CoreMai.jl")
include("D20-60/optim-CoreMai.jl")

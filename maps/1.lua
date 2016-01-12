return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "v0.11.0-27-g244d82d",
  orientation = "orthogonal",
  width = 30,
  height = 8,
  tilewidth = 64,
  tileheight = 64,
  nextobjectid = 4,
  backgroundcolor = { 180, 240, 255 },
  properties = {},
  tilesets = {
    {
      name = "green_tiles",
      firstgid = 1,
      tilewidth = 64,
      tileheight = 64,
      spacing = 0,
      margin = 0,
      tileoffset = {
        x = 0,
        y = 0
      },
      properties = {},
      terrains = {},
      tiles = {
        {
          id = 0,
          image = "../images/green_tiles/1.png",
          width = 64,
          height = 64
        },
        {
          id = 1,
          image = "../images/green_tiles/2.png",
          width = 64,
          height = 64
        },
        {
          id = 2,
          image = "../images/green_tiles/3.png",
          width = 64,
          height = 64
        },
        {
          id = 3,
          image = "../images/green_tiles/4.png",
          width = 64,
          height = 64
        },
        {
          id = 4,
          image = "../images/green_tiles/5.png",
          width = 64,
          height = 64
        },
        {
          id = 5,
          image = "../images/green_tiles/6.png",
          width = 64,
          height = 64
        },
        {
          id = 6,
          image = "../images/green_tiles/7.png",
          width = 64,
          height = 64
        },
        {
          id = 7,
          image = "../images/green_tiles/8.png",
          width = 64,
          height = 64
        },
        {
          id = 8,
          image = "../images/green_tiles/9.png",
          width = 64,
          height = 64
        },
        {
          id = 9,
          image = "../images/green_tiles/10.png",
          width = 64,
          height = 64
        },
        {
          id = 10,
          image = "../images/green_tiles/11.png",
          width = 64,
          height = 64
        },
        {
          id = 11,
          image = "../images/green_tiles/12.png",
          width = 64,
          height = 64
        },
        {
          id = 12,
          image = "../images/green_tiles/13.png",
          width = 64,
          height = 64
        },
        {
          id = 13,
          image = "../images/green_tiles/14.png",
          width = 64,
          height = 64
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "tiles",
      x = 0,
      y = 0,
      width = 30,
      height = 8,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 14,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 14, 7,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 3, 3, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 14, 7, 7,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 14, 7, 7, 13, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 14, 7, 7, 7,
        3, 3, 3, 3, 3, 3, 3, 3, 3, 14, 7, 7, 7, 7, 13, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 14, 7, 7, 7, 7,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
      }
    },
    {
      type = "objectgroup",
      name = "collisions",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          id = 1,
          name = "",
          type = "",
          shape = "rectangle",
          x = 0,
          y = 384,
          width = 1920,
          height = 128,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 2,
          name = "",
          type = "",
          shape = "polygon",
          x = 576,
          y = 384,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 128, y = -128 },
            { x = 256, y = -128 },
            { x = 384, y = 0 }
          },
          properties = {}
        },
        {
          id = 3,
          name = "",
          type = "",
          shape = "polygon",
          x = 1600,
          y = 384,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 320, y = -320 },
            { x = 320, y = 0 }
          },
          properties = {}
        }
      }
    }
  }
}

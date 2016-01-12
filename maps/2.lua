return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "v0.11.0-27-g244d82d",
  orientation = "orthogonal",
  width = 50,
  height = 8,
  tilewidth = 64,
  tileheight = 64,
  nextobjectid = 9,
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
      width = 50,
      height = 8,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 3, 3, 3, 3, 11, 0,
        11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 14, 7, 7, 7, 7, 13, 11,
        13, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 3, 3, 3, 3, 10, 0, 0, 12, 14, 7, 7, 7, 7, 7, 7, 13,
        7, 13, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 3, 3, 3, 3, 10, 0, 0, 0, 0, 0, 0, 0, 6, 8, 0, 0, 0, 12, 14, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 13, 11, 12, 3, 3, 3, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 8, 0, 0, 12, 14, 7, 7, 7, 7, 7, 7, 7, 7, 7,
        7, 7, 7, 13, 14, 7, 7, 7, 13, 3, 3, 11, 0, 0, 0, 0, 12, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
        7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 13, 11, 0, 0, 12, 14, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7
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
          id = 2,
          name = "",
          type = "",
          shape = "polygon",
          x = 256,
          y = 384,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 64, y = -64 },
            { x = 256, y = -64 },
            { x = 320, y = 0 }
          },
          properties = {}
        },
        {
          id = 3,
          name = "",
          type = "",
          shape = "polygon",
          x = 0,
          y = 384,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 0, y = -256 },
            { x = 256, y = 0 }
          },
          properties = {}
        },
        {
          id = 4,
          name = "",
          type = "",
          shape = "polygon",
          x = 0,
          y = 512,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 0, y = -128 },
            { x = 704, y = -128 },
            { x = 832, y = 0 }
          },
          properties = {}
        },
        {
          id = 5,
          name = "",
          type = "",
          shape = "polygon",
          x = 960,
          y = 512,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 128, y = -128 },
            { x = 2240, y = -128 },
            { x = 2240, y = 0 }
          },
          properties = {}
        },
        {
          id = 6,
          name = "",
          type = "",
          shape = "rectangle",
          x = 1408,
          y = 256,
          width = 384,
          height = 64,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 7,
          name = "",
          type = "",
          shape = "rectangle",
          x = 2112,
          y = 192,
          width = 384,
          height = 64,
          rotation = 0,
          visible = true,
          properties = {}
        },
        {
          id = 8,
          name = "",
          type = "",
          shape = "polygon",
          x = 2496,
          y = 384,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          polygon = {
            { x = 0, y = 0 },
            { x = 320, y = -320 },
            { x = 576, y = -320 },
            { x = 704, y = -192 },
            { x = 704, y = 0 }
          },
          properties = {}
        }
      }
    }
  }
}

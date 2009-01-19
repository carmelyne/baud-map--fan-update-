--Most of the map size information, aswell as the minimap sizes used by this addon were borrowed from Astrolabe
local NextUpdate = 0;
local MaxMarkers = 0;
local FriendList = {};
local Indoors, MapName, MapWidth, ShowLandmarks, ShowFlags;
local BlizTooltipText, BaudTooltipText;
local ZoneMapUpdater;
local FriendRoster = {};
--local RefreshCount, RefreshCost = 0, 0;
--Localizing functions to increase efficiency
local sqrt = sqrt;
local cos = cos;
local sin = sin;

local WorldMapSize = {
  World = 47714.27770954026,

  Kalimdor  = 36800.210572494,
  Ashenvale = 5766.728884700476,
  Aszhara = 5070.888165752819,
  AzuremystIsle = 4070.883253576282,
  Barrens = 10133.44343943073,
  BloodmystIsle = 3262.517428121028,
  Darkshore = 6550.06962983463,
  Darnassis = 1058.342927027606,
  Desolace = 4495.882023201739,
  Durotar = 5287.558038649864,
  Dustwallow = 5250.057259791282,
  Felwood = 5750.062034325837,
  Feralas = 6950.075260353015,
  Moonglade = 2308.356845256911,
  Mulgore = 5137.555355060729,
  Ogrimmar = 1402.621211455915,
  Silithus = 3483.371975265956,
  StonetalonMountains = 4883.385977951072,
  Tanaris = 6900.073766103516,
  Teldrassil = 5091.720903621394,
  TheExodar = 1056.781131437323,
  ThousandNeedles = 4400.046681282484,
  ThunderBluff = 1043.761263579803,
  UngoroCrater = 3700.040077455555,
  Winterspring = 7100.077599808275,

  Azeroth = 40741.175327834, --EasternKingdoms
  Alterac = 2800.000436369314,
  Arathi = 3599.999380663208,
  Badlands = 2487.498490907989,
  BlastedLands = 3349.999381676505,
  BurningSteppes = 2929.16694293186,
  DeadwindPass = 2499.999888210889,
  DunMorogh = 4924.998791911572,
  Duskwood = 2699.999669551933,
  EasternPlaguelands = 4031.249051993366,
  Elwynn = 3470.831971412848,
  EversongWoods = 4924.998483501337,
  Ghostlands = 3300.002855743766,
  Hilsbrad = 3200.000391416799,
  Hinterlands = 3849.998492380244,
  Ironforge = 790.6252518322632,
  LochModan = 2758.33360594204,
  Redridge = 2170.833229570681,
  SearingGorge = 2231.250200533406,
  SilvermoonCity = 1211.458551923779,
  Silverpine = 4200.000573479695,
  Stormwind = 1737.498058940429,
  Stranglethorn = 6381.248484543122,
  Sunwell = 3327.084777999942,
  SwampOfSorrows = 2293.753807610138,
  Tirisfal = 4518.749381850256,
  Undercity = 959.3752013853186,
  WesternPlaguelands = 4299.998717025251,
  Westfall = 3500.001170481545,
  Wetlands = 4135.414389381328,

  Expansion01 = 17463.987300595, --Outland
  BladesEdgeMountains = 5424.972055480694,
  Hellfire = 5164.556104714847,
  Nagrand = 5524.971495006054,
  Netherstorm = 5574.970083688359,
  ShadowmoonValley = 5499.971770418525,
  ShattrathCity = 1306.242821388422,
  TerokkarForest = 5399.971351016305,
  Zangarmarsh = 5027.057650868489,

  WarsongGulch = 1146.2,
  AlteracValley = 4237.4,
  NetherstormArena = 2271.6, --Eye of the Storm
  ArathiBasin = 1306.3,
  StrandoftheAncients = 1216.5,
  
  Northrend = 17751.3936186856,
  BoreanTundra = 5764.58206497758,
  CrystalsongForest = 2722.916164555434,
  Dalaran = 830.014625253355,
  
  Dragonblight = 5608.331259502691,
  GrizzlyHills = 5249.9986179934,
  HowlingFjord = 6045.831339550668,
  IcecrownGlacier = 6270.831861693458,
  LakeWintergrasp = 2974.999377667768,
  SholazarBasin = 4356.248328680455,
  TheStormPeaks = 7112.498205872217,
  ZulDrak = 4993.747919923504,
  
};


--Maps listed here will show their landmarks on the minimap.  Most maps already do this, but not all.
local LandmarkMaps = {
  ArathiBasin = true,
  AlteracValley = true,
};

local MinimapSize = {
  { --Outdoor
    [0] = 466 + 2/3, -- scale
    [1] = 400,       -- 7/6
    [2] = 333 + 1/3, -- 1.4
    [3] = 266 + 2/6, -- 1.75
    [4] = 200,       -- 7/3
    [5] = 133 + 1/3, -- 3.5
  },
  { --Indoor
    [0] = 300, -- scale
    [1] = 240, -- 1.25
    [2] = 180, -- 5/3
    [3] = 120, -- 2.5
    [4] = 80,  -- 3.75
    [5] = 50,  -- 6
  },
}


--[[Layering:
5 Landmark Overlay
4 Friends
3 PlayerArrow
2 Flags
1 Players
0 Landmarks
]]

--Raises the arrow on the world map above the markers placed on the map
local function RaiseArrow(Frame, Level)
  for _, Object in ipairs({Frame:GetChildren()})do
    if Object:IsObjectType("Model")and(Object:GetModel()=="Interface\\Minimap\\MinimapArrow")then
      Object:SetFrameLevel(Frame:GetFrameLevel() + Level + 1);
      return Object;
    end
  end
end


local function UpdateVisibility()
  if MapWidth and((#FriendRoster > 0)or ShowLandmarks or ShowFlags)then
    BaudMapMinimap:Show();
  else
    BaudMapMinimap:Hide();
  end
end


local EventFuncs = {
  PLAYER_LOGIN = function()
    BaudMapUpdateFriends();
    BaudMapUpdateWidth();
    --"ZONE_CHANGED_NEW_AREA"
  end,

  FRIENDLIST_UPDATE = function()
    BaudMapUpdateFriends();
  end,

  WORLD_MAP_UPDATE = function()
    BaudMapUpdateWidth();
  end,

  MINIMAP_UPDATE_ZOOM = function()
    local Zoom = Minimap:GetZoom();
    if(GetCVar("minimapZoom") == GetCVar("minimapInsideZoom"))then
      if(Zoom < 2)then
        Minimap:SetZoom(Zoom + 1);
      else
        Minimap:SetZoom(Zoom - 1);
      end
    end
    Indoors = (tonumber(GetCVar("minimapZoom")) == Minimap:GetZoom())and 1 or 2;
    Minimap:SetZoom(Zoom);
  end,

	ZONE_CHANGED_NEW_AREA = function()
	  if not WorldMapFrame:IsShown()then
      SetMapToCurrentZone();
    end
  end,

  PARTY_MEMBERS_CHANGED = function()
    BaudMapUpdateParty();
  end,
};


function BaudMap_OnLoad(self)
  for Key, Value in pairs(EventFuncs)do
    self:RegisterEvent(Key);
  end

  RaiseArrow(WorldMapFrame, 1);  --Ontop of: Players
  RaiseArrow(Minimap, 3);  --Ontop of: Landmarks, Players, Flags

  local function OnTooltipCleared()
    BaudTooltipText = nil;
    BlizTooltipText = nil;
  --  ChatFrame1:AddMessage("Tooltip Cleared");
  end

  if GameTooltip:GetScript("OnTooltipCleared")then
    GameTooltip:HookScript("OnTooltipCleared", OnTooltipCleared);
  else
    GameTooltip:SetScript("OnTooltipCleared", OnTooltipCleared);
  end

  DEFAULT_CHAT_FRAME:AddMessage("Baud Map: AddOn Loaded.  Version "..GetAddOnMetadata("BaudMap","Version")..".");
end


function BaudMap_OnEvent(self, event)
  EventFuncs[event]();
end


WorldMapFrame:HookScript("OnHide",function()
  SetMapToCurrentZone();
end)


function BaudMapUpdateWidth()
  local Instance, Type = IsInInstance();
  if Instance and(Type~="pvp")then
    MapWidth = nil;
  else
    ShowFlags = Instance and(Type=="pvp");
    local OldName = MapName;
    MapName = GetMapInfo() or "World";
    MapWidth = WorldMapSize[MapName];
    ShowLandmarks = LandmarkMaps[MapName];
    if not MapWidth and(OldName~=MapName)then
      DEFAULT_CHAT_FRAME:AddMessage("BaudMap: No width set for "..MapName);
    end
  end
  UpdateVisibility();
end


function BaudMapUpdateFriends()
  wipe(FriendList);
  local Name;
  for Index = 1, GetNumFriends()do
    Name = GetFriendInfo(Index);
    if Name then
      FriendList[Name] = true;
    end
  end
  BaudMapUpdateParty();
end


function BaudMapUpdateParty()
  local Max, Type;
  if(GetNumRaidMembers() > 0)then
    Max, Type = MAX_RAID_MEMBERS, "Raid";
  elseif(GetNumPartyMembers() > 0)then
    Max, Type = MAX_PARTY_MEMBERS, "Party";
  end
  local Key = 1;
  if Type then
    if ZoneMapUpdater then
      ZoneMapUpdater:Show();
    end
    local Friend, Unit;
    for Index = 1, Max do
      Unit = Type..Index;
      if UnitIsConnected(Unit)and not UnitIsUnit(Unit, "player")then
        Name, Server = UnitName(Unit);
        Friend = (not Server or(Server==""))and FriendList[Name];
        if Friend then
          FriendRoster[Key] = Type..Index;
          Key = Key + 1;
        end
      end
    end
  elseif ZoneMapUpdater then
    ZoneMapUpdater:Hide();
  end
  for Key = Key, #FriendRoster do
    FriendRoster[Key] = nil;
  end
  UpdateVisibility();
end


local UpdatedTooltip, MarkerIndex, MinimapRadius, PixelRadius, WidthMultiplier, HeightMultiplier, Scale, MouseIn, Level;
local X, Y, PX, PY, MX, MY;
local Marker, Overlay, Icon, OverIcon, InRange, Unit, Angle, Name, Server, Friend, S, C;
local Prefix, Total, Name, Description, Texture, Token, Facing, Distance;

local function Finish()
  for Index = MarkerIndex + 1, MaxMarkers do
    getglobal("BaudMinimapMarker"..Index):Hide();
  end
  if(UpdatedTooltip~=BaudTooltipText)and(not GameTooltip:IsShown()or(GameTooltip:GetOwner()==Minimap))then
    if GameTooltip:IsShown()and not BaudTooltipText then
      BlizTooltipText = GameTooltipTextLeft1:GetText();
    end
    if not UpdatedTooltip and not BlizTooltipText then
      GameTooltip:Hide();
    else
      local Text = BlizTooltipText;
      if UpdatedTooltip then
        if Text then
          Text = Text.."\n"..UpdatedTooltip;
        else
          Text = UpdatedTooltip;
        end
      end
      if GameTooltip:IsShown()then
        GameTooltipTextLeft1:SetText(Text);
      else
        GameTooltip:SetOwner(Minimap, "ANCHOR_CURSOR");
        GameTooltip:AddLine(Text);
      end
      GameTooltip:Show();
    end
    BaudTooltipText = UpdatedTooltip;
  end
end

local function AddTooltip(Frame, Text)
  if(MX < Frame:GetLeft())or(MX > Frame:GetRight())or(MY < Frame:GetBottom())or(MY > Frame:GetTop())then
    return;
  end
  if UpdatedTooltip then
    UpdatedTooltip = UpdatedTooltip.."\n"..Text;
  else
    UpdatedTooltip = Text;
  end
end

local function PlaceMarker(X, Y, ShowArrow)
  Marker = nil;
  if(X==0)and(Y==0)then
    return;
  end
  X = (X - PX) * WidthMultiplier;
  Y = (PY - Y) * HeightMultiplier;
  Distance = sqrt(X * X + Y * Y);
  InRange = (Distance < 0.9);
  if not InRange and not ShowArrow then
    return;
  end
  MarkerIndex = MarkerIndex + 1;
  Marker = getglobal("BaudMinimapMarker"..MarkerIndex);
  if not Marker then
    Marker = CreateFrame("Frame", "BaudMinimapMarker"..MarkerIndex, BaudMapMinimap);
    Icon = Marker:CreateTexture(Marker:GetName().."Icon");
    Icon:SetAllPoints();
    Overlay = CreateFrame("Frame", Marker:GetName().."Over", Marker);
    Overlay:SetAllPoints();
    OverIcon = Overlay:CreateTexture(Overlay:GetName().."Icon");
    OverIcon:SetAlpha(0.6);
    OverIcon:SetAllPoints();
    MaxMarkers = MarkerIndex;
  else
    Icon = getglobal(Marker:GetName().."Icon");
    Overlay = getglobal(Marker:GetName().."Over");
    OverIcon = getglobal(Overlay:GetName().."Icon");
  end
  if(Facing ~= 0)or not InRange then
    Angle = atan2(Y, X) + Facing;
    if InRange then
      X = cos(Angle) * Distance;
      Y = sin(Angle) * Distance;
    end
  end
  if InRange then
    --Icon:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon");
    Marker:SetPoint("CENTER", Minimap, "CENTER", X * PixelRadius, Y * PixelRadius);
  else
    Icon:SetTexture("Interface\\Minimap\\ROTATING-MINIMAPARROW");
    Marker:SetWidth(52); --26
    Marker:SetHeight(52); --26
--[[    S, C = sin(Angle + 45) * 0.5, cos(Angle + 45) * 0.5;
    Icon:SetTexCoord(
      0.5 - S, 0.5 + C,
      0.5 + C, 0.5 + S,
      0.5 - C, 0.5 - S,
      0.5 + S, 0.5 - C
    );]]
    Icon:SetRotation((Angle - 90) / 180 * math.pi);
    Marker:SetPoint("CENTER", Minimap, "CENTER", (PixelRadius - 15) * cos(Angle), (PixelRadius - 15) * sin(Angle));
    Overlay:Hide();
  end
  Marker:Show();
end


function BaudMapMinimap_OnUpdate()
  --[[if(GetTime() < NextUpdate)then
    return;
  end
  NextUpdate = GetTime() + 0.1;]]

  UpdatedTooltip = nil;
  MarkerIndex = 0;

  PX, PY = GetPlayerMapPosition("player");
  if(PX==0)and(PY==0)then
    Finish();
    return;
  end
  MinimapRadius = MinimapSize[Indoors][Minimap:GetZoom()] / 2;
  PixelRadius = Minimap:GetWidth() / 2;
  if not MinimapRadius then
    Finish();
    return;
  end

  WidthMultiplier = MapWidth / MinimapRadius;
  HeightMultiplier = (MapWidth * 2) / 3 / MinimapRadius;
  MX, MY = GetCursorPosition();
  Scale = Minimap:GetEffectiveScale();
  MX, MY = MX / Scale, MY / Scale;
  X, Y = Minimap:GetCenter();
  X, Y = X - MX, Y - MY;
  MouseIn = (sqrt(X * X + Y * Y) < PixelRadius);
  Level = Minimap:GetFrameLevel() + 1;
  Facing = MiniMapCompassRing:GetFacing() / math.pi * 180;

--[[    PlaceMarker(0.5, 0.5, true);
    if Marker then
      Overlay:Hide();
      if InRange then
        Marker:SetWidth(16);
        Marker:SetHeight(16);
        Icon:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon");
        Icon:SetTexCoord(0, 1, 0, 1);
      end
      Marker:SetFrameLevel(Level + 4);
      Icon:SetVertexColor(0.1, 1, 0.1);
    end]]

  for Key, Unit in ipairs(FriendRoster)do
    X, Y = GetPlayerMapPosition(Unit);
    PlaceMarker(X, Y, true);
    if Marker then
      Overlay:Hide();
      if InRange then
        Marker:SetWidth(16);
        Marker:SetHeight(16);
        Icon:SetTexture("Interface\\WorldMap\\WorldMapPartyIcon");
        Icon:SetTexCoord(0, 1, 0, 1);
      end
      Marker:SetFrameLevel(Level + 4);
      Icon:SetVertexColor(0.1, 1, 0.1);
    end
  end

  if ShowLandmarks then
    for Index = 1, GetNumMapLandmarks()do
      Name, Description, Texture, X, Y = GetMapLandmarkInfo(Index);
      PlaceMarker(X, Y, false);
      if Marker then
        Marker:SetWidth(16);
        Marker:SetHeight(16);
        Marker:SetFrameLevel(Level);
        Icon:SetTexture("Interface\\Minimap\\POIIcons");
        Icon:SetTexCoord(WorldMap_GetPOITextureCoords(Texture));
        Icon:SetVertexColor(1, 1, 1);
        OverIcon:SetTexture("Interface\\Minimap\\POIIcons");
        OverIcon:SetTexCoord(WorldMap_GetPOITextureCoords(Texture));
        Overlay:SetFrameLevel(Level + 5);
        Overlay:Show();
        if MouseIn then
          AddTooltip(Marker, Name);
        end
      end
    end
  end

  for Index = 1, GetNumBattlefieldFlagPositions() do
    X, Y, Token = GetBattlefieldFlagPosition(Index);
    PlaceMarker(X, Y, false);
    if Marker then
      Marker:SetWidth(24);
      Marker:SetHeight(24);
      Icon:SetTexture("Interface\\WorldStateFrame\\"..Token);
      Icon:SetTexCoord(0, 1, 0, 1);
      Icon:SetVertexColor(1, 1, 1);
      OverIcon:SetTexture("Interface\\WorldStateFrame\\"..Token);
      OverIcon:SetTexCoord(0, 1, 0, 1);
      Overlay:SetFrameLevel(Level + 5);
      Overlay:Show();
      Marker:SetFrameLevel(Level);
    end
  end
  Finish();
end


hooksecurefunc("WorldMapButton_OnUpdate", function()
  local Marker, Icon, Text, Name, Server;
  local Level = WorldMapButton:GetFrameLevel() + 1;

  local Max, Type;
  if(GetNumRaidMembers() > 0)then
    Max, Type = MAX_RAID_MEMBERS, "Raid";
  else
    Max, Type = MAX_PARTY_MEMBERS, "Party";
  end

  for Index = 1, Max do
    Marker = getglobal("WorldMap"..Type..Index);
    if Marker:IsShown()then
      Icon = getglobal(Marker:GetName().."Icon");
      Text = getglobal(Marker:GetName().."Text");
      if not Text then
        Text = Marker:CreateFontString(Marker:GetName().."Text", "ARTWORK", "GameFontHighlightSmall");
        Text:SetPoint("LEFT", Marker, "RIGHT");
        Text:Show();
      end
      if Marker.unit then
        Name, Server = UnitName(Marker.unit);
      else
        Name, Server = Marker.name, nil;
      end
      Text:SetText(Name or "Unknown");
      if Name and(not Server or(Server==""))and FriendList[Name]then
        Text:SetTextColor(0.1, 1, 0.1);
        Icon:SetVertexColor(0.1, 1, 0.1);
        Marker:SetFrameLevel(Level + 2);
        Marker.Friend = true;
      else
        Text:SetTextColor(1, 1, 1);
        Icon:SetVertexColor(1, 1, 1);
        Marker:SetFrameLevel(Level);
        Marker.Friend = false;
      end
    end
  end
end);


hooksecurefunc("MapUnit_OnUpdate", function(self)
  if self.Friend then
    getglobal(self:GetName().."Icon"):SetVertexColor(0.1, 1, 0.1);
    return;
  end
end);


local BGMapHooked;
local ZoneMapThrottle = 0;
hooksecurefunc("BattlefieldMinimap_LoadUI", function()
  if BGMapHooked then
    return;
  end
  BGMapHooked = true;
  RaiseArrow(BattlefieldMinimap, 2);  --Ontop of: Landmarks(level unchecked), Players

  ZoneMapUpdater = CreateFrame("Frame", "BaudMapZoneMap", BattlefieldMinimap)
  if(GetNumPartyMembers()==0)or(GetNumRaidMembers()==0)then
    ZoneMapUpdater:Hide();
  end
  ZoneMapUpdater:SetScript("OnUpdate", function()
    if(GetTime() <= ZoneMapThrottle)then
      return;
    end
    ZoneMapThrottle = GetTime() + 1;

    local Marker, Name, Server;
    local Level = BattlefieldMinimap:GetFrameLevel() + 1;
    local Max, Type, X, Y;
    local MarkerIndex = 0;

    if(GetNumRaidMembers() > 0)then
      Max, Type = MAX_RAID_MEMBERS, "Raid";
    else
      Max, Type = MAX_PARTY_MEMBERS, "Party";
    end
    local Skip;

    for Index = 1, Max do
      if(Type=="Party")then
        MarkerIndex = Index;
      else
        X, Y = GetPlayerMapPosition("raid"..Index);
        if(X ~= 0)or(Y ~= 0)and not UnitIsUnit("raid"..Index, "player")then
          MarkerIndex = MarkerIndex + 1;
          Skip = false;
        else
          Skip = true;
        end
      end
      if not Skip then
        Marker = getglobal("BattlefieldMinimap"..Type..MarkerIndex);
        if(Type=="Raid")then
         --Fixes Blizzard's BG Minimap.  Taint is possible.
          Marker.unit = "raid"..Index;
        end
        Icon = getglobal(Marker:GetName().."Icon");
        if Marker:IsShown()then
          Name, Server = UnitName(Marker.unit);
          if Name and(not Server or(Server==""))and FriendList[Name]then
            Marker:SetFrameLevel(Level + 3);
            --Icon:SetVertexColor(0.1, 1, 0.1);
            Marker.Friend = true;
          else
            Marker:SetFrameLevel(Level + 1);
            --Icon:SetVertexColor(1, 1, 1);
            Marker.Friend = nil;
          end
        end
      end
    end
  end);
end);
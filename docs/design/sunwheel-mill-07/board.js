// Composition review only; the compiled kit owns geometry and neutral piece sizing.
(() => {
  const kit = window.STARFALL_LEVEL_DESIGN_KIT;
  window.STARFALL_RESTORATION_REVIEW = {
    locationID: 7,
    assetPrefix: 'SunwheelMill',
    exportName: 'sunwheelMillBoardReview',
    pieceRendering: kit.piece,
    layoutReferences: {
      phone: kit.layouts.phone,
      'tablet-portrait': kit.layouts['ipad-portrait'],
      'tablet-landscape': kit.layouts['ipad-landscape']
    },
    stateNames: ['The mill is quiet', 'The bearing wakes', 'Light links the workshop', 'The outlet stays closed', 'Light goes onward'],
    stateDescriptions: [
      'The copper wheel, glass inserts and channels are quiet. The crafted workshop remains, with its outlet physically closed.',
      'The center bearing and one rounded vane insert glow. A short inlet responds; the other inserts and outlet remain quiet.',
      'Three vane inserts glow and light connects through the mill channels. Some workshop lamps answer; the outlet stays closed.',
      'All five inserts, workshop lamps and upstream channels are restored. The copper outlet is still shut, and the onward channel remains dark.',
      'The copper outlet leaves separate around a visible opening. Contained golden light follows the onward channel; all earlier restoration remains.'
    ]
  };
})();

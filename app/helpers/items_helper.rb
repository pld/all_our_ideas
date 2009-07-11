module ItemsHelper
  def activate_link(id, active, qid = nil)
    text = active > 0 ? t('common.deactivate') : t('common.activate')
    link_to text, state_admin_item_path(id, :active => active, :question_id => qid)
  end

  def gmap(locs, label = nil)
    text = "
      google.load('visualization', '1', {'packages': ['geomap']});
      google.setOnLoadCallback(drawMap);

      function drawMap() {
        var data = new google.visualization.DataTable();
        data.addRows(#{locs.length});
        data.addColumn('number', 'LATITUDE', 'Latitude');
        data.addColumn('number', 'LONGITUDE', 'Longitude');
        data.addColumn('number', '#{label || t('items.number_of_votes')}', 'Value');
        data.addColumn('string', 'HOVER', 'HoverText');"
    0.upto(locs.length - 1) do |i|
      text << "\n\tdata.setValue(#{i}, 0, #{locs[i][0]});"
      text << "\n\tdata.setValue(#{i}, 1, #{locs[i][1]});"
      text << "\n\tdata.setValue(#{i}, 2, #{locs[i][3]});"
      text << "\n\tdata.setValue(#{i}, 3, '#{locs[i][2]}');"
    end
    text << "
        var options = {};
        options['region'] = 'world';
        options['width'] = '700px';
        options['height'] = '400px';
        //options['colors'] = [0xFF8747, 0xFFB581, 0xc06000]; //orange colors
        options['dataMode'] = 'markers';

        var container = document.getElementById('map_canvas');
        var geomap = new google.visualization.GeoMap(container);
        geomap.draw(data, options);
      };"
    text
  end
end
